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
            connectingLabel: '{translate key=Connecting|escape:"javascript"}',
            onlineLabel: '{translate key=Connected|escape:"javascript"}',
            offlineLabel: '{translate key=ConnectionLost|escape:"javascript"}',
            retryingLabel: '{translate key=RetryingConnection|escape:"javascript"}',
            startsInLabel: '{translate key=MeetingStartsIn|escape:"javascript"}',
            endsInLabel: '{translate key=MeetingEndsIn|escape:"javascript"}',
            startsNowLabel: '{translate key=MeetingStartsNow|escape:"javascript"}',
            endsNowLabel: '{translate key=MeetingEndsNow|escape:"javascript"}',
            durationHoursLabel: '{translate key=DurationHours|escape:"javascript"}',
            durationMinutesLabel: '{translate key=DurationMinutes|escape:"javascript"}',
            bookingFailedMessage: '{translate key=BookingFailed|escape:"javascript"}',
            checkinFailedMessage: '{translate key=CheckInFailed|escape:"javascript"}',
        });
    });
</script>

{include file='globalfooter.tpl' PoweredByDisplay=true}
