{include file='globalheader.tpl' HideNavBar=true cssFiles='css/schedule.css,css/resource-display.css'}

<div id="page-resource-display-resource" class="resource-display-page">
    <div id="booking-date-toolbar" class="focus-date-toolbar container-fluid d-none">
        <label for="availabilityStartDate">{translate key=BookingDate}</label>
        <input type="text" id="availabilityStartDate" class="form-control" aria-label="{translate key=BookingDate}" />
    </div>
    <div id="placeholder" aria-live="polite">
        <div class="focus-loading" role="status"><span class="spinner-border spinner-border-sm" aria-hidden="true"></span> {translate key=LoadingRoomDisplay}</div>
    </div>
</div>

<div class="modal" id="wait-modal" tabindex="-1" role="dialog" aria-labelledby="waitModalLabel"
    data-bs-backdrop="static" aria-hidden="true">
    {include file="wait-box.tpl" translateKey='Working'}
</div>

{include file="javascript-includes.tpl"}
{jsfile src="resourceDisplay.js"}
{jsfile src="ajax-helpers.js"}
{jsfile src="autocomplete.js"}

{control type="DatePickerSetupControl" ControlId="availabilityStartDate" MaxDate=$MaxFutureDate MinDate=$MinDate DefaultDate=$MinDate}

{capture assign=displayConnectingLabel}{translate key=Connecting}{/capture}
{capture assign=displayOnlineLabel}{translate key=RoomDisplayUpdatedJustNow}{/capture}
{capture assign=displayOfflineLabel}{translate key=ConnectionLost}{/capture}
{capture assign=displayRetryingLabel}{translate key=RetryingConnection}{/capture}
{capture assign=displayStartsNowLabel}{translate key=MeetingStartsNow}{/capture}
{capture assign=displayEndsNowLabel}{translate key=MeetingEndsNow}{/capture}
{capture assign=displayDurationHourLabel}{translate key=RoomDisplayHour}{/capture}
{capture assign=displayDurationHoursLabel}{translate key=RoomDisplayHours}{/capture}
{capture assign=displayDurationMinuteLabel}{translate key=RoomDisplayMinute}{/capture}
{capture assign=displayDurationMinutesLabel}{translate key=RoomDisplayMinutes}{/capture}
{capture assign=displayDurationAbbreviatedHoursLabel}{translate key=DurationHours}{/capture}
{capture assign=displayDurationAbbreviatedMinutesLabel}{translate key=DurationMinutes}{/capture}
{capture assign=displayUnavailableLabel}{translate key=RoomDisplayUnavailable}{/capture}
{capture assign=displayReconnectingMessage}{translate key=RoomDisplayReconnecting}{/capture}
{capture assign=displayLastUpdatedAtLabel}{translate key=RoomDisplayLastUpdatedAt}{/capture}
{capture assign=displayLiveAvailabilityLabel}{translate key=RoomDisplayLiveAvailabilityReturns}{/capture}
{capture assign=displayBookingFailedMessage}{translate key=BookingFailed}{/capture}
{capture assign=displayCheckinFailedMessage}{translate key=CheckInFailed}{/capture}

<script type="text/javascript">
    function getResourceId() {
        return '{$PublicResourceId|escape:"javascript"}';
    }
    $(function() {
        var resourceDisplay = new ResourceDisplay();
        resourceDisplay.initDisplay({
            url: '{$smarty.server.SCRIPT_NAME}?dr=resource&rid={$PublicResourceId|escape:"url"}&dr=display',
            userAutocompleteUrl: "ajax/autocomplete.php?type={AutoCompleteType::User}&as=1",
            allowAutocomplete: {if $AllowAutocomplete}true{else}false{/if},
            refreshInterval: 60000,
            connectingLabel: '{$displayConnectingLabel|escape:"javascript"}',
            onlineLabel: '{$displayOnlineLabel|escape:"javascript"}',
            offlineLabel: '{$displayOfflineLabel|escape:"javascript"}',
            retryingLabel: '{$displayRetryingLabel|escape:"javascript"}',
            startsNowLabel: '{$displayStartsNowLabel|escape:"javascript"}',
            endsNowLabel: '{$displayEndsNowLabel|escape:"javascript"}',
            durationHourWordLabel: '{$displayDurationHourLabel|escape:"javascript"}',
            durationHoursWordLabel: '{$displayDurationHoursLabel|escape:"javascript"}',
            durationMinuteWordLabel: '{$displayDurationMinuteLabel|escape:"javascript"}',
            durationMinutesWordLabel: '{$displayDurationMinutesLabel|escape:"javascript"}',
            durationHoursLabel: '{$displayDurationAbbreviatedHoursLabel|escape:"javascript"}',
            durationMinutesLabel: '{$displayDurationAbbreviatedMinutesLabel|escape:"javascript"}',
            unavailableLabel: '{$displayUnavailableLabel|escape:"javascript"}',
            reconnectingMessage: '{$displayReconnectingMessage|escape:"javascript"}',
            lastUpdatedAtLabel: '{$displayLastUpdatedAtLabel|escape:"javascript"}',
            liveAvailabilityLabel: '{$displayLiveAvailabilityLabel|escape:"javascript"}',
            bookingFailedMessage: '{$displayBookingFailedMessage|escape:"javascript"}',
            checkinFailedMessage: '{$displayCheckinFailedMessage|escape:"javascript"}',
        });
    });
</script>

{include file='globalfooter.tpl' PoweredByDisplay=true}
