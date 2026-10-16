{assign var=activeReservation value=null}
{if $CurrentReservation != null}
    {assign var=activeReservation value=$CurrentReservation}
{elseif $StartingSoon && $NextReservation != null}
    {assign var=activeReservation value=$NextReservation}
{/if}

<div id="resource-display" class="resource-display focus-display" data-timezone="{$Timezone|escape:'html'}"
    data-schedule-today="{$Today->Format('Y-m-d')}" data-now="{$Now->Timestamp()}">
    <header class="focus-top">
        <div class="focus-brand"><span class="focus-brand-mark" aria-hidden="true"></span>hellomeet</div>
        <span class="focus-room-display-caption">{translate key=RoomDisplay}</span>
    </header>

    <div class="focus-room-row">
        <div class="focus-room-details">
            {if $RoomLocation}<div class="focus-room-location">{$RoomLocation|escape}</div>{/if}
            <h1>{$ResourceName|escape}</h1>
            {if $RoomCapacity || $RoomDescription}
                <div class="focus-room-metadata">
                    {if $RoomCapacity}<span class="focus-inline"><i class="bi bi-people" aria-hidden="true"></i> {$RoomCapacity} {translate key=RoomDisplayPeople}</span>{/if}
                    {if $RoomDescription}<span class="focus-inline"><i class="bi bi-display" aria-hidden="true"></i> {$RoomDescription|escape}</span>{/if}
                </div>
            {/if}
        </div>
        <div class="focus-clock">
            <time id="room-clock" class="focus-clock-time" aria-label="{translate key=LocalTime}">{format_date date=$Now key=res_popup_time timezone=$Timezone}</time>
            <div class="focus-clock-date" id="room-date">{formatdate date=$Today key=schedule_daily timezone=$Timezone}</div>
            <div class="focus-clock-zone" id="room-timezone">{$Timezone|escape}</div>
        </div>
    </div>

    <main class="focus-content">
        <section class="focus-current focus-status-card"
            data-state="{if $CurrentReservation != null}booked{elseif $StartingSoon}soon{elseif $NoMeetingsToday}empty{else}available{/if}"
            aria-labelledby="room-status-heading">
            <div class="focus-status">
                <span class="focus-status-dot" aria-hidden="true"></span>
                <span id="room-status-heading" class="focus-status-label">
                    {if $CurrentReservation != null}{translate key=MeetingInProgress}
                    {elseif $StartingSoon}{translate key=StartingSoon}
                    {else}{translate key=RoomDisplayAvailableStatus}{/if}
                </span>
            </div>

            <h2 class="focus-hero-word">
                {if $CurrentReservation != null}{translate key=RoomBooked}
                {elseif $StartingSoon}{translate key=RoomDisplayUpNextHero}
                {elseif $NoMeetingsToday}{translate key=RoomDisplayAllYours}
                {else}{translate key=RoomDisplayComeOnIn}{/if}
            </h2>

            {if $activeReservation != null}
                {if $activeReservation.group != null}
                    <div class="focus-host">
                        {if $activeReservation.group.logoFileName}
                            <div class="focus-host-logo"><img src="{$GroupLogoBaseUrl|escape:'html'}{$activeReservation.group.logoFileName|escape:'url'}" alt="" /></div>
                        {else}
                            <div class="focus-host-logo focus-host-initials" aria-hidden="true">{$activeReservation.group.initials|escape}</div>
                        {/if}
                        <div class="focus-host-copy">
                            <div class="focus-host-label">{if $StartingSoon}{translate key=RoomDisplayNextHost}{else}{translate key=HostedBy}{/if}</div>
                            <div class="focus-host-name">{$activeReservation.group.name|escape}</div>
                        </div>
                    </div>
                {/if}

                <h3 class="focus-meeting">{$activeReservation.title|escape}</h3>
                <p class="focus-time">
                    <time data-time-timestamp="{$activeReservation.startTimestamp}">{format_date date=$activeReservation.startDate key=res_popup_time timezone=$Timezone}</time>
                    <span aria-hidden="true">–</span>
                    <time data-time-timestamp="{$activeReservation.endTimestamp}">{format_date date=$activeReservation.endDate key=res_popup_time timezone=$Timezone}</time>
                </p>

                <div class="focus-countdown-row">
                    <div>
                        <strong class="focus-countdown" data-countdown-target="{if $CurrentReservation != null}{$activeReservation.endTimestamp}{else}{$activeReservation.startTimestamp}{/if}">--:--</strong>
                        <span class="focus-countdown-label">{if $CurrentReservation != null}{translate key=RoomDisplayUntilMeetingEnds}{else}{translate key=RoomDisplayUntilNextMeeting}{/if}</span>
                    </div>
                    {if $RequiresCheckin && $CheckinReservation != null}
                        <form role="form" method="post" id="formCheckin"
                            action="{$smarty.server.SCRIPT_NAME}?action=checkin&rid={$PublicResourceId|escape:'url'}">
                            <input type="hidden" {formname key=REFERENCE_NUMBER} value="{$CheckinReferenceNumber|escape:'html'}" />
                            <button type="submit" id="checkin" class="focus-checkin-action" data-public-action="true">
                                <i class="bi bi-check" aria-hidden="true"></i>{translate key=RoomDisplayCheckIn}
                            </button>
                        </form>
                    {elseif $CheckinEnabled && $CheckinConfirmationReservation != null}
                        <p class="focus-checkin-confirmation" role="status">{translate key=RoomDisplayCheckedIn}</p>
                    {/if}
                </div>
            {elseif $NextReservation != null}
                <h3 class="focus-meeting">{translate key=RoomDisplayAvailableInvitation}</h3>
                <p class="focus-time">{translate key=RoomDisplayNextMeetingAt} <time data-time-timestamp="{$NextReservation.startTimestamp}">{format_date date=$NextReservation.startDate key=res_popup_time timezone=$Timezone}</time></p>
                <div class="focus-countdown-row">
                    <div>
                        <strong class="focus-countdown" data-countdown-target="{$NextReservation.startTimestamp}">--:--</strong>
                        <span class="focus-countdown-label">{translate key=RoomDisplayUntilNextMeeting}</span>
                    </div>
                </div>
            {else}
                <h3 class="focus-meeting">{translate key=RoomDisplayNoMoreMeetings}</h3>
                <p class="focus-time">{translate key=RoomDisplayAvailableRestOfDay}</p>
            {/if}

            <p id="checkin-feedback" class="focus-checkin-feedback d-none" role="alert"></p>
        </section>

        <aside class="focus-agenda" aria-labelledby="agenda-heading">
            <div class="focus-agenda-heading">
                <h2 id="agenda-heading">{translate key=RoomDisplayAgendaHeading}</h2>
                <span>{translate key=Today}</span>
            </div>
            {if $UpcomingReservations|count > 0}
                <ol class="focus-agenda-list">
                    {foreach from=$UpcomingReservations item=reservation name=upcoming}
                        <li class="focus-agenda-item" data-start-ts="{$reservation.startTimestamp}" data-end-ts="{$reservation.endTimestamp}">
                            <div class="focus-event-top">
                                <span class="focus-event-time" data-start-ts="{$reservation.startTimestamp}" data-end-ts="{$reservation.endTimestamp}">
                                    {format_date date=$reservation.startDate key=res_popup_time timezone=$Timezone}
                                    <span aria-hidden="true">–</span>
                                    {format_date date=$reservation.endDate key=res_popup_time timezone=$Timezone}
                                </span>
                                {if $smarty.foreach.upcoming.first}<span class="focus-next-tag">{translate key=Next}</span>{/if}
                            </div>
                            <h3 class="focus-agenda-title">{$reservation.title|escape}</h3>
                            <span class="focus-duration" aria-label="{translate key=Duration}"></span>
                            {if $reservation.group != null}
                                <div class="focus-event-host">
                                    {if $reservation.group.logoFileName}
                                        <img src="{$GroupLogoBaseUrl|escape:'html'}{$reservation.group.logoFileName|escape:'url'}" alt="" class="focus-event-logo" />
                                    {else}
                                        <span class="focus-event-initials" aria-hidden="true">{$reservation.group.initials|escape}</span>
                                    {/if}
                                    <span class="focus-event-host-name">{$reservation.group.name|escape}</span>
                                </div>
                            {/if}
                        </li>
                    {/foreach}
                </ol>
            {else}
                <p class="focus-agenda-empty">{translate key=RoomDisplayEmptyAgenda}</p>
            {/if}
        </aside>
    </main>

    <footer class="focus-footer">
        <span id="connection-status" class="focus-connection-status" role="status" aria-live="polite" data-state="connecting">
            <span class="focus-connection-dot" aria-hidden="true"></span><span class="connection-message">{translate key=Connecting}</span><time id="last-updated" class="visually-hidden">--:--</time>
        </span>
        <div class="focus-footer-actions">
            <span>{translate key=RoomDisplayAvailabilityNote}</span>
            {if $ReservationsAllowed}
                <button type="button" id="reservePopup" class="focus-book-link" data-bs-toggle="modal" data-bs-target="#reservation-box" data-public-action="true">
                    {translate key=BookThisRoom} ↗
                </button>
            {/if}
        </div>
    </footer>

    {if $ReservationsAllowed}
        <div class="modal fade" id="reservation-box" tabindex="-1" aria-labelledby="reservation-title" aria-hidden="true">
            <div class="modal-dialog modal-fullscreen">
                <div class="modal-content">
                    <div class="modal-header">
                        <h2 class="modal-title fs-4" id="reservation-title">{translate key=BookThisRoom}</h2>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="{translate key=Close}"></button>
                    </div>
                    <div class="modal-body">
                        <div id="booking-date-placeholder"></div>
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
                            <input type="hidden" id="reservationBeginDate" {formname key=BEGIN_DATE} value="{$ReservationDate}" />
                        </form>
                    </div>
                </div>
            </div>
        </div>
    {/if}
</div>
