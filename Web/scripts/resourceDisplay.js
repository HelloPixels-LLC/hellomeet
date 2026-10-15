function ResourceDisplay(opts) {
  var elements = {
    loginForm: $('#loginForm'),
    loginButton: $('#loginButton'),
    loginError: $('#loginError'),
    loginBox: $('#login-box'),
    resourceList: $('#resourceList'),
    resourceListBox: $('#resource-list-box'),
    activateResourceDisplayForm: $('#activateResourceDisplayForm'),
    placeholder: $('#placeholder'),
    startDate: $('#availabilityStartDate'),
    bookingDateToolbar: $('#booking-date-toolbar'),
  };

  var refreshEnabled = true;

  function populateResourceList(resources) {
    $.each(resources || [], function (i, resource) {
      elements.resourceList.append($('<option/>', { value: resource.id, text: resource.name }));
    });
    elements.resourceListBox.removeClass('no-show');
  }

  function activateResourceDisplay(resourceId) {
    $('#wait-modal').modal('show');
    ajaxPost(elements.activateResourceDisplayForm, null, null, function (data) {
      if (data.location) {
        window.location = data.location;
      } else {
        $('#wait-modal').modal('hide');
      }
    });
  }

  ResourceDisplay.prototype.init = function () {
    elements.loginForm.submit(function (e) {
      e.preventDefault();
      ajaxPost(elements.loginForm, null, null, function (data) {
        if (data.error == true) {
          elements.loginError.removeClass('no-show');
        } else {
          elements.loginBox.addClass('no-show');
          populateResourceList(data.resources);
        }
        hideWait();
      });
    });
  };

  ResourceDisplay.prototype.initDisplay = function (options) {
    var manualDateOverride = false;
    var refreshInProgress = false;
    var refreshRequested = false;
    var nextRefreshTimer = null;
    var retryDelay = 5000;
    var midnightRefreshPending = false;
    var refreshInterval = options.refreshInterval || 60000;
    var lastSuccessfulRefreshAt = null;
    var staleAfter = refreshInterval + 15000;

    setConnectionStatus('connecting', options.connectingLabel);
    refreshResource();
    updateClock();
    window.setInterval(updateClock, 1000);

    elements.placeholder.on('click', '#reservePopup', function () {
      pauseRefresh();
    });

    elements.placeholder.on('hidden.bs.modal', '#reservation-box', function () {
      resumeRefresh();
      refreshResource();
    });

    elements.placeholder.on('click', '#reserveCancel', function () {
      resumeRefresh();
      refreshResource();
    });

    elements.placeholder.on('submit', '#formReserve', function (event) {
      event.preventDefault();
      event.stopPropagation();

      var validationErrors = $('#validationErrors');
      var beforeReserve = function () {
        validationErrors.addClass('d-none');
        showWait();
      };
      var afterReserve = function (data) {
        if (data.success) {
          validationErrors.find('ul').empty().addClass('d-none');
          $('#reservation-box').modal('hide');
          resumeRefresh();
          refreshResource();
        } else {
          var errors = data.errors || data.Messages || [];
          validationErrors
            .find('ul')
            .empty()
            .append(
              $.map(errors, function (item) {
                return $('<li/>', { text: item });
              })
            );
          validationErrors.removeClass('d-none');
        }
        hideWait();
      };

      var reserveForm = $('#formReserve');
      BeforeSerialize(reserveForm);
      beforeReserve();
      $.ajax({
        type: 'POST',
        url: reserveForm.attr('action'),
        data: reserveForm.serialize(),
        dataType: 'json',
        cache: false,
        timeout: 20000,
      })
        .done(afterReserve)
        .fail(function () {
          validationErrors
            .find('ul')
            .empty()
            .append($('<li/>', { text: options.bookingFailedMessage }));
          validationErrors.removeClass('d-none');
          markDisplayStale();
          setConnectionStatus('offline', options.offlineLabel);
        })
        .always(hideWait);
    });

    elements.placeholder.on('click', '.slot.reservable', function (event) {
      var slot = $(event.target).closest('.slot');
      $('#beginPeriod').val(slot.data('begin')).trigger('change');
      $('#endPeriod').val(slot.data('end'));
    });

    elements.placeholder
      .on('mouseenter', '.reservable', function () {
        $(this).addClass('hilite');
      })
      .on('mouseleave', '.reservable', function () {
        $(this).removeClass('hilite');
      });

    elements.startDate.on('change', function () {
      manualDateOverride = !_.isEmpty(elements.startDate.val());
      refreshResource();
    });

    function pauseRefresh() {
      refreshEnabled = false;
      if (nextRefreshTimer) {
        window.clearTimeout(nextRefreshTimer);
        nextRefreshTimer = null;
      }
    }

    function resumeRefresh() {
      refreshEnabled = true;
    }

    function refreshResource() {
      if (!refreshEnabled) {
        return;
      }
      if (refreshInProgress) {
        refreshRequested = true;
        return;
      }

      var requestUrl = options.url;
      if (manualDateOverride && !_.isEmpty(elements.startDate.val())) {
        requestUrl += '&sd=' + encodeURIComponent(elements.startDate.val());
      }

      refreshInProgress = true;
      $.ajax({
        type: 'GET',
        url: requestUrl,
        cache: false,
        timeout: 20000,
      })
        .done(function (html) {
          if (!refreshEnabled) {
            refreshInProgress = false;
            return;
          }
          var bookingDateToolbar = elements.bookingDateToolbar.detach().removeClass('d-none');
          elements.placeholder.html(html);
          var bookingDatePlaceholder = $('#booking-date-placeholder');
          if (bookingDatePlaceholder.length) {
            bookingDatePlaceholder.append(bookingDateToolbar);
          } else {
            elements.placeholder.prepend(bookingDateToolbar);
          }
          refreshInProgress = false;
          retryDelay = 5000;
          lastSuccessfulRefreshAt = Date.now();
          midnightRefreshPending = false;
          setConnectionStatus('online', options.onlineLabel);
          updateLastUpdated();
          bindCurrentForms();
          updateClock();
          if (refreshRequested) {
            refreshRequested = false;
            refreshResource();
          } else {
            scheduleRefresh(refreshInterval);
          }
        })
        .fail(function () {
          refreshInProgress = false;
          markDisplayStale();
          setConnectionStatus('offline', options.offlineLabel);
          refreshRequested = false;
          scheduleRefresh(retryDelay);
          retryDelay = Math.min(retryDelay * 2, 60000);
        });
    }

    function bindCurrentForms() {
      var checkinForm = $('#formCheckin');
      if (checkinForm.length) {
        checkinForm.off('submit.resourceDisplay');
        checkinForm.on('submit.resourceDisplay', function (event) {
          event.preventDefault();
          event.stopImmediatePropagation();
          BeforeSerialize(checkinForm);
          showWait();
          $.ajax({
            type: 'POST',
            url: checkinForm.attr('action'),
            data: checkinForm.serialize(),
            dataType: 'json',
            cache: false,
            timeout: 20000,
          })
            .done(function (response) {
              if (response && response.success) {
                refreshResource();
              } else {
                $('#checkin-feedback').text(options.checkinFailedMessage).removeClass('d-none');
              }
            })
            .fail(function () {
              markDisplayStale();
              setConnectionStatus('offline', options.offlineLabel);
            })
            .always(hideWait);
          return false;
        });
      }

      var begin = $('#beginPeriod');
      var end = $('#endPeriod');
      var beginIndex = begin.find('option:selected').index();
      begin.off('change.resourceDisplay').on('change.resourceDisplay', function () {
        var newIndex = begin.find('option:selected').index();
        var endIndex = end.find('option:selected').index();
        var adjustedEndIndex = Math.max(0, Math.min(end.find('option').length - 1, endIndex + newIndex - beginIndex));
        end.prop('selectedIndex', adjustedEndIndex);
        beginIndex = newIndex;
      });

      if (options.allowAutocomplete) {
        var email = $('#emailAddress');
        email.off('focus.resourceDisplay keyup.resourceDisplay');
        email.userAutoComplete(options.userAutocompleteUrl, function (ui) {
          email.val(ui.item.data.Email);
        });
      }
    }

    function scheduleRefresh(delay) {
      if (nextRefreshTimer) {
        window.clearTimeout(nextRefreshTimer);
      }
      nextRefreshTimer = window.setTimeout(function () {
        nextRefreshTimer = null;
        refreshResource();
      }, delay);
    }

    function setConnectionStatus(state, label) {
      var status = $('#connection-status');
      if (!status.length) {
        return;
      }
      status.attr('data-state', state);
      status.find('.connection-message').text(label || '');
    }

    function markDisplayStale() {
      var display = $('#resource-display');
      if (display.length) {
        display.addClass('is-stale');
        display.find('.focus-status-card').attr('data-state', 'stale');
        display.find('.focus-status-label').text(options.offlineLabel || 'Connection lost');
        display.find('[data-public-action], #formCheckin button, #formReserve :input').prop('disabled', true);
      } else {
        elements.placeholder.find('.focus-loading').text(options.offlineLabel || 'Connection lost');
      }
    }

    function updateLastUpdated() {
      var root = $('#resource-display');
      var timezone = root.data('timezone');
      var lastUpdated = $('#last-updated');
      if (!lastUpdated.length) {
        return;
      }
      lastUpdated.text(formatTime(new Date(), timezone, false));
    }

    function updateClock() {
      var root = $('#resource-display');
      if (!root.length) {
        return;
      }

      var timezone = root.data('timezone');
      var clock = $('#room-clock');
      var date = $('#room-date');
      if (lastSuccessfulRefreshAt !== null && Date.now() - lastSuccessfulRefreshAt > staleAfter) {
        markDisplayStale();
        setConnectionStatus('offline', options.offlineLabel);
      }
      try {
        clock.text(formatTime(new Date(), timezone, true));
        date.text(
          new Intl.DateTimeFormat(undefined, {
            timeZone: timezone,
            weekday: 'long',
            month: 'long',
            day: 'numeric',
            year: 'numeric',
          }).format(new Date())
        );
      } catch {
        clock.text(new Date().toLocaleTimeString());
        date.text(new Date().toLocaleDateString());
      }

      updateCountdowns();
      updateDurations();

      var scheduleToday = String(root.data('schedule-today') || '');
      var localToday = dateInTimezone(new Date(), timezone);
      if (scheduleToday && localToday !== scheduleToday && !midnightRefreshPending) {
        midnightRefreshPending = true;
        manualDateOverride = false;
        elements.startDate.val('');
        refreshResource();
      }
    }

    function formatTime(date, timezone, includeSeconds) {
      return new Intl.DateTimeFormat(undefined, {
        timeZone: timezone,
        hour: '2-digit',
        minute: '2-digit',
        second: includeSeconds ? '2-digit' : undefined,
        hour12: false,
      }).format(date);
    }

    function dateInTimezone(date, timezone) {
      var parts = new Intl.DateTimeFormat('en-CA', {
        timeZone: timezone,
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
      }).formatToParts(date);
      var values = {};
      $.each(parts, function (index, part) {
        values[part.type] = part.value;
      });
      return values.year + '-' + values.month + '-' + values.day;
    }

    function updateCountdowns() {
      $('.focus-countdown[data-countdown-target]').each(function () {
        var countdown = $(this);
        var remaining = Math.max(0, Math.floor(Number(countdown.data('countdown-target')) - Date.now() / 1000));
        var hours = Math.floor(remaining / 3600);
        var minutes = Math.floor((remaining % 3600) / 60);
        var seconds = remaining % 60;
        var text = (hours > 0 ? hours + ':' + pad(minutes) : minutes) + ':' + pad(seconds);
        countdown.text(text);

        if (remaining === 0) {
          var label = $('#resource-display').find('.focus-countdown-label');
          label.text(
            $('#resource-display').find('.focus-status-card').data('state') === 'booked'
              ? options.endsNowLabel
              : options.startsNowLabel
          );
          if (!countdown.data('refreshQueued')) {
            countdown.data('refreshQueued', true);
            window.setTimeout(refreshResource, 1200);
          }
        }
      });
    }

    function updateDurations() {
      $('.focus-agenda-item').each(function () {
        var row = $(this);
        var seconds = Math.max(0, Number(row.data('end-ts')) - Number(row.data('start-ts')));
        var totalMinutes = Math.floor(seconds / 60);
        var hours = Math.floor(totalMinutes / 60);
        var minutes = totalMinutes % 60;
        var duration = '';
        if (hours > 0) {
          duration += hours + ' ' + options.durationHoursLabel;
        }
        if (minutes > 0 || duration === '') {
          duration += (duration ? ' ' : '') + minutes + ' ' + options.durationMinutesLabel;
        }
        row.find('.focus-duration').text(duration);
      });
    }

    function pad(number) {
      return number < 10 ? '0' + number : String(number);
    }
  };

  function showWait() {
    $('#wait-modal').modal('show');
  }

  function hideWait() {
    $('#wait-modal').modal('hide');
  }

  elements.loginButton.click(function (event) {
    event.preventDefault();
    showWait();
    elements.loginForm.submit();
  });

  elements.resourceList.on('change', function () {
    var resourceId = $(this).val();
    if (resourceId !== '') {
      activateResourceDisplay(resourceId);
    }
  });
}
