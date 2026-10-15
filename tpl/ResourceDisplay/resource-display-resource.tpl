{assign var=activeReservation value=null}
{if $CurrentReservation != null}
    {assign var=activeReservation value=$CurrentReservation}
{elseif $StartingSoon && $NextReservation != null}
    {assign var=activeReservation value=$NextReservation}
{/if}

<div id="resource-display" class="resource-display focus-display" data-timezone="{$Timezone|escape:'html'}"
    data-schedule-today="{$Today->Format('Y-m-d')}" data-now="{$Now->Timestamp()}">
    <header class="focus-header container-fluid">
        <div class="focus-brand-room">
            <div class="focus-wordmark" aria-label="HelloMeet">Hello<span>Meet</span></div>
            <div class="focus-room-details">
                <h1>{$ResourceName|escape}</h1>
                <div class="focus-room-metadata">
                    {if $RoomLocation}<span><i class="bi bi-geo-alt" aria-hidden="true"></i> {$RoomLocation|escape}</span>{/if}
                    {if $RoomCapacity}<span><i class="bi bi-people" aria-hidden="true"></i> {$RoomCapacity} {translate key=Seats}</span>{/if}
                </div>
            </div>
        </div>
        <div class="focus-clock-block">
            <time class="focus-clock" id="room-clock" aria-label="{translate key=LocalTime}">--:--</time>
            <div class="focus-clock-meta">
                <time id="room-date">{formatdate date=$Today key=schedule_daily timezone=$Timezone}</time>
                <span id="room-timezone">{$Timezone|escape}</span>
            </div>
        </div>
    </header>

    <div id="booking-date-placeholder"></div>

    <main class="container-fluid focus-main">
        <div class="row g-4 align-items-stretch">
            <section class="col-12 col-xl-7" aria-labelledby="room-status-heading">
                <div class="focus-status-card shadow-sm" data-state="{if $CurrentReservation != null}booked{elseif $StartingSoon}starting-soon{elseif $NoMeetingsToday}empty-day{else}available{/if}">
                    <div class="focus-status-topline">
                        <span class="focus-status-dot" aria-hidden="true"></span>
                        <span id="room-status-heading" class="focus-status-label">
                            {if $CurrentReservation != null}{translate key=RoomBooked}
                            {elseif $StartingSoon}{translate key=StartingSoon}
                            {elseif $NoMeetingsToday}{translate key=NoMeetingsToday}
                            {else}{translate key=RoomAvailable}{/if}
                        </span>
                        <span class="focus-status-date">{formatdate date=$ReservationDate key=schedule_daily timezone=$Timezone}</span>
                    </div>

                    {if $activeReservation != null}
                        <div class="focus-meeting-main">
                            <div class="focus-meeting-copy">
                                <p class="focus-eyebrow">{if $CurrentReservation != null}{translate key=CurrentMeeting}{else}{translate key=NextMeeting}{/if}</p>
                                <h2>{$activeReservation.title|escape}</h2>
                                <p class="focus-meeting-time">
                                    {format_date date=$activeReservation.startDate key=res_popup_time timezone=$Timezone}
                                    <span aria-hidden="true">–</span>
                                    {format_date date=$activeReservation.endDate key=res_popup_time timezone=$Timezone}
                                </p>
                                {if $activeReservation.ownerName}
                                    <p class="focus-meeting-owner">{translate key=HostedBy} {$activeReservation.ownerName|escape}</p>
                                {/if}
                            </div>
                            {if $activeReservation.group != null}
                                <div class="focus-group-brand" aria-label="{translate key=HostedBy} {$activeReservation.group.name|escape}">
                                    {if $activeReservation.group.logoFileName}
                                        <img src="{$GroupLogoBaseUrl|escape:'html'}{$activeReservation.group.logoFileName|escape:'url'}"
                                            alt="" class="focus-group-logo" />
                                    {else}
                                        <span class="focus-group-initials" aria-hidden="true">{$activeReservation.group.initials|escape}</span>
                                    {/if}
                                    <span class="focus-group-name">{$activeReservation.group.name|escape}</span>
                                </div>
                            {/if}
                        </div>
                        <div class="focus-countdown-row">
                            <span class="focus-countdown-label">{if $CurrentReservation != null}{translate key=MeetingEndsIn}{else}{translate key=MeetingStartsIn}{/if}</span>
                            <strong class="focus-countdown" data-countdown-target="{if $CurrentReservation != null}{$activeReservation.endTimestamp}{else}{$activeReservation.startTimestamp}{/if}">--:--</strong>
                        </div>
                    {else}
                        <div class="focus-empty-state">
                            <div class="focus-empty-icon"><i class="bi bi-door-open" aria-hidden="true"></i></div>
                            <h2>{if $NoMeetingsToday}{translate key=NoMeetingsToday}{else}{translate key=RoomAvailableNow}{/if}</h2>
                            <p>{if $NoMeetingsToday}{translate key=NoMeetingsScheduled}{else}{translate key=RoomReadyForBooking}{/if}</p>
                        </div>
                    {/if}

                    {if $RequiresCheckin && $CheckinReservation != null}
                        <form role="form" method="post" id="formCheckin"
                            action="{$smarty.server.SCRIPT_NAME}?action=checkin&rid={$PublicResourceId|escape:'url'}">
                            <input type="hidden" {formname key=REFERENCE_NUMBER} value="{$CheckinReferenceNumber|escape:'html'}" />
                            <button type="submit" id="checkin" class="btn focus-checkin-action" data-public-action="true">
                                <i class="bi bi-check-circle" aria-hidden="true"></i>
                                {translate key=CheckIn}
                                <span class="focus-checkin-time">{format_date date=$CheckinReservation.startDate key=res_popup_time timezone=$Timezone}</span>
                            </button>
                        </form>
                        <p id="checkin-feedback" class="focus-checkin-feedback d-none" role="alert"></p>
                    {elseif $CheckinEnabled && $CheckinConfirmationReservation != null}
                        <p class="focus-checkin-confirmation" role="status">
                            <i class="bi bi-check-circle-fill" aria-hidden="true"></i>
                            {translate key=MeetingCheckedIn}
                            <span>{$CheckinConfirmationReservation.title|escape} · {format_date date=$CheckinConfirmationReservation.startDate key=res_popup_time timezone=$Timezone}</span>
                        </p>
                    {/if}
                </div>
            </section>

            <aside class="col-12 col-xl-5" aria-labelledby="agenda-heading">
                <div class="focus-agenda-card shadow-sm">
                    <div class="focus-agenda-heading">
                        <div>
                            <p class="focus-eyebrow">{formatdate date=$ReservationDate key=schedule_daily timezone=$Timezone}</p>
                            <h2 id="agenda-heading">{translate key=UpcomingMeetings}</h2>
                        </div>
                        <span class="focus-agenda-count">{$UpcomingReservations|count}</span>
                    </div>
                    {if $UpcomingReservations|count > 0}
                        <ol class="focus-agenda-list">
                            {foreach from=$UpcomingReservations item=reservation}
                                <li class="focus-agenda-item" data-start-ts="{$reservation.startTimestamp}" data-end-ts="{$reservation.endTimestamp}">
                                    <div class="focus-agenda-time">
                                        <strong>{format_date date=$reservation.startDate key=res_popup_time timezone=$Timezone}</strong>
                                        <span>{format_date date=$reservation.endDate key=res_popup_time timezone=$Timezone}</span>
                                    </div>
                                    <div class="focus-agenda-details">
                                        <h3>{$reservation.title|escape}</h3>
                                        <span class="focus-duration" aria-label="{translate key=Duration}"></span>
                                        {if $reservation.ownerName}<span class="focus-agenda-owner">{$reservation.ownerName|escape}</span>{/if}
                                    </div>
                                    {if $reservation.group != null}
                                        <div class="focus-agenda-brand" title="{$reservation.group.name|escape}">
                                            {if $reservation.group.logoFileName}
                                                <img src="{$GroupLogoBaseUrl|escape:'html'}{$reservation.group.logoFileName|escape:'url'}" alt="" />
                                            {else}
                                                <span aria-hidden="true">{$reservation.group.initials|escape}</span>
                                            {/if}
                                        </div>
                                    {/if}
                                </li>
                            {/foreach}
                        </ol>
                    {else}
                        <div class="focus-agenda-empty">
                            <i class="bi bi-calendar2-check" aria-hidden="true"></i>
                            <p>{translate key=NoUpcomingMeetings}</p>
                        </div>
                    {/if}
                </div>
            </aside>
        </div>

        {if $ReservationsAllowed}
            <div class="focus-booking-row">
                <button type="button" id="reservePopup" class="btn focus-book-button" data-bs-toggle="modal" data-bs-target="#reservation-box" data-public-action="true">
                    <i class="bi bi-plus-lg" aria-hidden="true"></i> {translate key=BookThisRoom}
                </button>
            </div>

            <div class="modal fade" id="reservation-box" tabindex="-1" aria-labelledby="reservation-title" aria-hidden="true">
                <div class="modal-dialog modal-fullscreen">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h2 class="modal-title fs-4" id="reservation-title">{translate key=BookThisRoom}</h2>
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="{translate key=Close}"></button>
                        </div>
                        <div class="modal-body">
                            <form role="form" method="post" id="formReserve" action="{$smarty.server.SCRIPT_NAME}?action=reserve&rid={$PublicResourceId|escape:'url'}">
                                <div id="validationErrors" class="validationSummary alert alert-danger d-none"><ul></ul></div>
                                <div class="focus-slot-table-wrap">
                                    <table class="reservations focus-slot-table">
                                        <thead><tr>{foreach from=$DailyLayout->GetPeriods($ReservationDate, true) item=period}<td class="reslabel" colspan="{$period->Span()}">{$period->Label($ReservationDate)}</td>{/foreach}</tr></thead>
                                        <tbody><tr>
                                            {assign var=slots value=$DailyLayout->GetLayout($ReservationDate, $ResourceId)}
                                            {foreach from=$slots item=slot}
                                                {assign var="referenceNumber" value=""}
                                                {if $slot->IsReserved()}{assign var="class" value="reserved"}{elseif $slot->IsReservable()}{assign var="class" value="reservable"}{if $slot->IsPastDate(Date::Now())}{assign var="class" value="pasttime"}{/if}{else}{assign var="class" value="unreservable"}{/if}
                                                <td colspan="{$slot->PeriodSpan()}" data-begin="{$slot->Begin()}" data-end="{$slot->End()}" class="slot {$class}" data-refnum="{$referenceNumber}">
                                                    {if $slot->IsReserved()}{translate key=Reserved}{else}{$slot->Label($SlotLabelFactory)|escape|default:'&nbsp;'}{/if}
                                                </td>
                                            {/foreach}
                                        </tr></tbody>
                                    </table>
                                </div>
                                <div class="row g-3 mt-2">
                                    <div class="col-12"><label for="emailAddress" class="form-label">{translate key=Email}</label><input id="emailAddress" type="email" class="form-control form-control-lg" placeholder="{translate key=Email}" required="required" {formname key=EMAIL} /></div>
                                    <div class="col-6"><label for="beginPeriod" class="form-label">{translate key=Begin}</label><select title="{translate key=Begin}" class="form-select form-select-lg" id="beginPeriod" {formname key=BEGIN_PERIOD}>{foreach from=$slots item=slot}{if $slot->IsReservable() && !$slot->IsPastDate($ReservationDate)}<option value="{$slot->Begin()}">{$slot->Begin()->Format($TimeFormat)}</option>{/if}{/foreach}</select></div>
                                    <div class="col-6"><label for="endPeriod" class="form-label">{translate key=End}</label><select title="{translate key=End}" class="form-select form-select-lg" id="endPeriod" {formname key=END_PERIOD}>{foreach from=$slots item=slot}{if $slot->IsReservable() && !$slot->IsPastDate($ReservationDate)}<option value="{$slot->End()}">{$slot->End()->Format($TimeFormat)}</option>{/if}{/foreach}</select></div>
                                </div>
                                {if $Terms != null}<div class="mt-3" id="termsAndConditions"><div class="form-check"><input class="form-check-input" type="checkbox" id="termsAndConditionsAcknowledgement" {formname key=TOS_ACKNOWLEDGEMENT} {if $TermsAccepted}checked="checked"{/if} /><label class="form-check-label" for="termsAndConditionsAcknowledgement">{translate key=IAccept}</label> <a href="{$Terms->DisplayUrl()|escape:'html'}" class="link-primary" target="_blank" rel="noopener noreferrer">{translate key=TheTermsOfService}</a></div></div>{/if}
                                {if $Attributes|default:array()|count > 0}<div class="mt-3"><div class="customAttributes row gy-3">{foreach from=$Attributes item=attribute}<div class="customAttribute col-12 col-md-6">{control type="AttributeControl" attribute=$attribute}</div>{/foreach}</div></div>{/if}
                                <div class="d-grid gap-2 mt-4"><input type="submit" class="action-reserve btn btn-primary btn-lg" value="{translate key=Reserve}" /><button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal" id="reserveCancel">{translate key=Cancel}</button></div>
                                <input type="hidden" {formname key=RESOURCE_ID} value="{$ResourceId}" />
                                <input type="hidden" {formname key=SCHEDULE_ID} value="{$ScheduleId}" />
                                <input type="hidden" {formname key=TIMEZONE} value="{$Timezone|escape:'html'}" />
                                <input type="hidden" {formname key=BEGIN_DATE} value="{$ReservationDate}" />
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        {/if}
    </main>

    <footer class="focus-footer container-fluid">
        <span id="connection-status" class="focus-connection-status" role="status" aria-live="polite">
            <span class="focus-connection-dot" aria-hidden="true"></span><span class="connection-message">{translate key=Connecting}</span>
        </span>
        <span class="focus-last-updated">{translate key=LastUpdated}: <time id="last-updated">--:--</time></span>
    </footer>
</div>
