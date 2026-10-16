<?php

require_once(ROOT_DIR . 'Presenters/ActionPresenter.php');
require_once(ROOT_DIR . 'lib/Application/Authorization/namespace.php');
require_once(ROOT_DIR . 'lib/Application/Authentication/namespace.php');
require_once(ROOT_DIR . 'lib/Application/Schedule/namespace.php');
require_once(ROOT_DIR . 'Domain/Access/namespace.php');
require_once(ROOT_DIR . 'Pages/Ajax/IReservationSaveResultsView.php');
require_once(ROOT_DIR . 'lib/Application/Reservation/PrivacyFilter.php');
require_once(ROOT_DIR . 'lib/Application/Admin/ImageUploadDirectory.php');

class ResourceDisplayPresenter extends ActionPresenter
{
    /**
     * @var IResourceDisplayPage
     */
    private $page;

    /**
     * @var IResourceRepository
     */
    private $resourceRepository;
    /**
     * @var IReservationService
     */
    private $reservationService;
    /**
     * @var IAuthorizationService
     */
    private $authorizationService;
    /**
     * @var IWebAuthentication
     */
    private $authentication;
    /**
     * @var IScheduleRepository
     */
    private $scheduleRepository;
    /**
     * @var IDailyLayoutFactory
     */
    private $dailyLayoutFactory;

    /**
     * @var IGuestUserService
     */
    private $guestUserService;

    /**
     * @var IReservationHandler
     */
    public $reservationCreateHandler;

    /**
     * @var IReservationHandler
     */
    public $reservationCheckinHandler;

    /**
     * @var IAttributeService
     */
    private $attributeService;

    /**
     * @var IReservationRepository
     */
    private $reservationRepository;

    /**
     * @var ITermsOfServiceRepository
     */
    private $termsOfServiceRepository;

    /** @var IGroupBrandingProvider|null */
    private $groupBrandingProvider;

    /** @var IPrivacyFilter */
    private $privacyFilter;

    public function __construct(
        IResourceDisplayPage $page,
        IResourceRepository $resourceRepository,
        IReservationService $reservationService,
        IAuthorizationService $authorizationService,
        IWebAuthentication $authentication,
        IScheduleRepository $scheduleRepository,
        IDailyLayoutFactory $dailyLayoutFactory,
        IGuestUserService $guestUserService,
        IAttributeService $attributeService,
        IReservationRepository $reservationRepository,
        ITermsOfServiceRepository $termsOfServiceRepository,
        ?IGroupBrandingProvider $groupBrandingProvider = null,
        ?IPrivacyFilter $privacyFilter = null
    ) {
        parent::__construct($page);
        $this->page = $page;
        $this->resourceRepository = $resourceRepository;
        $this->reservationService = $reservationService;
        $this->authorizationService = $authorizationService;
        $this->authentication = $authentication;
        $this->scheduleRepository = $scheduleRepository;
        $this->dailyLayoutFactory = $dailyLayoutFactory;
        $this->guestUserService = $guestUserService;
        $this->attributeService = $attributeService;
        $this->reservationRepository = $reservationRepository;
        $this->termsOfServiceRepository = $termsOfServiceRepository;
        $this->groupBrandingProvider = $groupBrandingProvider;
        $this->privacyFilter = $privacyFilter ?? new PrivacyFilter();

        parent::AddAction('login', 'Login');
        parent::AddAction('activate', 'Activate');
        parent::AddAction('reserve', 'Reserve');
        parent::AddAction('checkin', 'Checkin');
    }

    public function PageLoad()
    {
        $resourceId = $this->page->GetPublicResourceId();
        if (!empty($resourceId)) {
            $this->page->DisplayResourceShell();
        } else {
            $this->page->DisplayInstructions();
        }
    }

    public function Login()
    {
        $username = $this->page->GetEmail();
        $password = $this->page->GetPassword();

        $isValid = $this->authentication->Validate($username, $password);

        if ($isValid) {
            $this->authentication->Login($username, new WebLoginContext(new LoginData()));
            $user = ServiceLocator::GetServer()->GetUserSession();
            $resourceList = [];
            $resources = $this->resourceRepository->GetResourceList();
            foreach ($resources as $resource) {
                if ($this->authorizationService->CanEditForResource($user, $resource)) {
                    $resourceList[] = $resource;
                }
            }

            $this->page->BindResourceList($resourceList);
        } else {
            $this->page->BindInvalidLogin();
        }
    }

    public function Activate()
    {
        $resource = $this->resourceRepository->LoadById($this->page->GetResourceId());
        if ($this->authorizationService->CanEditForResource(ServiceLocator::GetServer()->GetUserSession(), $resource)) {
            $resource->EnableDisplay();
            $this->resourceRepository->Update($resource);
            $this->page->SetActivatedResourceId($resource->GetPublicId());
        }
    }

    public function DisplayResource($resourcePublicId, $startDate)
    {
        $resource = $this->resourceRepository->LoadByPublicId($resourcePublicId);

        if (!$resource->GetIsDisplayEnabled()) {
            $this->page->DisplayNotEnabled();
            return;
        }

        $scheduleId = $resource->GetScheduleId();

        $schedule = $this->scheduleRepository->LoadById($scheduleId);
        $timezone = $schedule->GetTimezone();

        $now = Date::Now()->ToTimezone($timezone);

        $layout = $this->scheduleRepository->GetLayout($scheduleId, new ScheduleLayoutFactory($timezone));
        if ($startDate instanceof Date) {
            $reservationDate = Date::Parse($startDate->Format('Y-m-d'), $timezone)->GetDate();
        } elseif (is_string($startDate) && $startDate !== '') {
            $reservationDate = Date::Parse($startDate, $timezone)->GetDate();
        } else {
            $reservationDate = $now->GetDate();
        }
        $slots = $layout->GetLayout($reservationDate, true);

        $reservationSearchRange = new DateRange($reservationDate->GetDate()->ToUtc(), $reservationDate->AddDays(1)->GetDate()->ToUtc());
        $reservations = $this->reservationService->GetReservations($reservationSearchRange, null, $timezone, $resource->GetResourceId());

        $attributes = $this->attributeService->GetReservationAttributes(
            new NullUserSession(),
            new ReservationView(),
            0,
            [$resource->GetResourceId()]
        );

        $requiredAttributes = [];
        /** @var LBAttribute $attribute */
        foreach ($attributes as $attribute) {
            if ($attribute->Required()) {
                $requiredAttributes[] = $attribute;
            }
        }
        $this->page->BindResource($resource);
        $this->page->BindSchedule($schedule);
        $this->page->BindAttributes($requiredAttributes);

        $dailyLayout = $this->dailyLayoutFactory->Create($reservations, $layout);

        $reservationList = $reservations->OnDateForResource($reservationDate, $resource->GetId());
        $hasReservationsToday = count($reservationList) > 0;

        $brandingByOwner = $this->ResolveOwnerBranding($reservationList);
        $publicReservationsByReference = [];

        /** @var ReservationListItem|null $next */
        $next = null;

        /** @var ReservationListItem[] $upcoming */
        $upcoming = [];

        $current = null;
        $eligibleCurrentCheckin = null;
        $eligibleUpcomingCheckin = null;

        /** @var ReservationListItem $r */
        foreach ($reservationList as $r) {
            if (($next == null || $r->StartDate()->LessThan($next->StartDate())) && $r->StartDate()->GreaterThan($now)) {
                $next = $r;
            }

            if ($r->CollidesWith($now)) {
                $current = $r;
            }

            if ($resource->IsCheckInEnabled() && $r->RequiresCheckin()) {
                if ($r->CollidesWith($now)) {
                    $eligibleCurrentCheckin = $r;
                } elseif ($r->StartDate()->GreaterThan($now) && $eligibleUpcomingCheckin == null) {
                    $eligibleUpcomingCheckin = $r;
                }
            }

            if ($r->StartDate()->GreaterThan($now)) {
                $upcoming[] = $r;
            }

            $publicReservationsByReference[$r->ReferenceNumber()] = $this->CreatePublicReservationData(
                $r,
                $brandingByOwner
            );
        }

        $checkinReservation = $eligibleCurrentCheckin ?? $eligibleUpcomingCheckin;
        $requiresCheckin = $checkinReservation != null;
        $checkinReferenceNumber = $checkinReservation == null ? '' : $checkinReservation->ReferenceNumber();

        $current = $current == null ? null : $publicReservationsByReference[$current->ReferenceNumber()];
        $next = $next == null ? null : $publicReservationsByReference[$next->ReferenceNumber()];
        $upcoming = array_map(
            static fn (ReservationListItem $reservation) => $publicReservationsByReference[$reservation->ReferenceNumber()],
            $upcoming
        );

        $this->SetTermsOfService();
        $this->page->SetIsAvailableNow($current == null);
        $this->page->DisplayAvailability($dailyLayout, $now, $reservationDate->GetDate(), $current, $next, $upcoming, $requiresCheckin, $checkinReferenceNumber, $hasReservationsToday);
    }

    public function Reserve()
    {
        if (!Configuration::Instance()->GetKey(ConfigKeys::TABLET_VIEW_ALLOW_RESERVATIONS, new BooleanConverter())) {
            $resultCollector = new ReservationResultCollector();
            $resultCollector->SetSaveSuccessfulMessage(false);
            $resultCollector->SetErrors(['Reservations are disabled in tablet view']);

            $this->page->SetReservationSaveResults(false, $resultCollector);
            return;
        }

        $resourceId = $this->page->GetResourceId();
        $email = $this->page->GetEmail();

        $resource = $this->resourceRepository->LoadByPublicId($this->page->GetPublicResourceId());
        if (!$resource->GetIsDisplayEnabled() || $resource->GetResourceId() != $resourceId) {
            $resultCollector = new ReservationResultCollector();
            $resultCollector->SetSaveSuccessfulMessage(false);
            $resultCollector->SetErrors(['Unauthorized']);
            $this->page->SetReservationSaveResults(false, $resultCollector);
            return;
        }

        $schedule = $this->scheduleRepository->LoadById($resource->GetScheduleId());
        $timezone = $schedule->GetTimezone();

        $reservationDate = Date::Parse($this->page->GetBeginDate(), $timezone)->Format('Y-m-d ');
        $date = DateRange::Create($reservationDate . $this->page->GetBeginTime(), $reservationDate . $this->page->GetEndTime(), $timezone);

        $maxFutureDays = Configuration::Instance()->GetKey(ConfigKeys::PRIVACY_PUBLIC_FUTURE_DAYS, new IntConverter());
        if ($maxFutureDays == 0) {
            $maxFutureDays = 1;
        }
        $requestedDate = Date::Parse($this->page->GetBeginDate(), $timezone)->GetDate();
        $maxDate = Date::Now()->ToTimezone($timezone)->GetDate()->AddDays($maxFutureDays - 1);

        $resultCollector = new ReservationResultCollector();

        if ($requestedDate->GreaterThan($maxDate)) {
            $resultCollector->SetSaveSuccessfulMessage(false);
            $resultCollector->SetErrors(['Unauthorized']);
            $success = false;
        } else {

            $userSession = $this->guestUserService->CreateOrLoad($email);
            $series = ReservationSeries::Create($userSession->UserId, $resource, Resources::GetInstance()->GetString('AdHocMeeting'), Resources::GetInstance()->GetString('AdHocMeeting'), $date, new RepeatNone(), $userSession);

            $series->AcceptTerms($this->page->GetTermsOfServiceAcknowledgement());

            $attributes = $this->page->GetAttributes();
            foreach ($attributes as $attribute) {
                $series->AddAttributeValue(new AttributeValue($attribute->Id, $attribute->Value));
            }

            $success = $this->GetHandler($userSession)->Handle($series, $resultCollector);
        }
        $this->page->SetReservationSaveResults($success, $resultCollector);
    }

    public function Checkin()
    {
        $resultCollector = new ReservationResultCollector();
        $resource = $this->resourceRepository->LoadByPublicId($this->page->GetPublicResourceId());
        if (!$resource->GetIsDisplayEnabled() || !$resource->IsCheckInEnabled()) {
            $resultCollector->SetSaveSuccessfulMessage(false);
            $resultCollector->SetErrors(['Unauthorized']);
            $this->page->SetReservationCheckinResults(false, $resultCollector);
            return;
        }

        $schedule = $this->scheduleRepository->LoadById($resource->GetScheduleId());
        $timezone = $schedule->GetTimezone();
        $now = Date::Now()->ToTimezone($timezone);
        $today = $now->GetDate();
        $range = new DateRange($today->ToUtc(), $today->AddDays(1)->ToUtc());
        $reservations = $this->reservationService->GetReservations($range, null, $timezone, $resource->GetResourceId());
        $eligibleCurrent = null;
        $eligibleUpcoming = null;
        foreach ($reservations->OnDateForResource($today, $resource->GetId()) as $reservation) {
            if (!$reservation->RequiresCheckin()) {
                continue;
            }

            if ($reservation->CollidesWith($now)) {
                $eligibleCurrent = $reservation;
                break;
            }

            if ($eligibleUpcoming == null && $reservation->StartDate()->GreaterThan($now)) {
                $eligibleUpcoming = $reservation;
            }
        }

        $eligibleReservation = $eligibleCurrent ?? $eligibleUpcoming;
        $referenceNumber = $this->page->GetReferenceNumber();
        if ($eligibleReservation == null || $eligibleReservation->ReferenceNumber() !== $referenceNumber) {
            $resultCollector->SetSaveSuccessfulMessage(false);
            $resultCollector->SetErrors(['Unauthorized']);
            $this->page->SetReservationCheckinResults(false, $resultCollector);
            return;
        }

        $series = $this->reservationRepository->LoadByReferenceNumber($referenceNumber);

        $userSession = new NullUserSession();
        $handler = $this->GetCheckinHandler($userSession);

        $series->Checkin($userSession);
        $success = $handler->Handle($series, $resultCollector);

        $this->page->SetReservationCheckinResults($success, $resultCollector);
    }

    public function ProcessDataRequest($dataRequest)
    {
        if ($dataRequest == 'display') {
            $resourceId = $this->page->GetPublicResourceId();
            $startDate = $this->page->GetStartDate();
            $this->DisplayResource($resourceId, $startDate);
        }
    }

    protected function LoadValidators($action)
    {
        if ($action == 'reserve') {
            $this->page->RegisterValidator('emailformat', new EmailValidator($this->page->GetEmail()));
            if (!Configuration::Instance()->GetKey(ConfigKeys::TABLET_VIEW_ALLOW_GUEST_RESERVATIONS, new BooleanConverter())) {
                $this->page->RegisterValidator('guestdenied', new RestrictedGuestValidator($this->page->GetEmail(), $this->guestUserService));
            }
        }
    }

    private function GetHandler($userSession)
    {
        if ($this->reservationCreateHandler == null) {
            return ReservationHandler::Create(
                ReservationAction::Create,
                new AddReservationPersistenceService($this->reservationRepository),
                $userSession
            );
        }

        return $this->reservationCreateHandler;
    }

    private function GetCheckinHandler($userSession)
    {
        if ($this->reservationCheckinHandler == null) {
            return ReservationHandler::Create(ReservationAction::Checkin, new UpdateReservationPersistenceService($this->reservationRepository), $userSession);
        }

        return $this->reservationCheckinHandler;
    }

    private function SetTermsOfService()
    {
        $termsOfService = $this->termsOfServiceRepository->Load();
        if ($termsOfService != null && $termsOfService->AppliesToReservation()) {
            $this->page->SetTerms($termsOfService);
        }
    }

    /**
     * @param ReservationListItem[] $reservations
     * @return array<int, array{groupId: int, name: string, logoFileName: ?string, initials: string}>
     */
    private function ResolveOwnerBranding(array $reservations)
    {
        if ($this->groupBrandingProvider == null) {
            return [];
        }

        $ownerIds = [];
        foreach ($reservations as $reservation) {
            $ownerId = (int)($reservation->ReservedItem()->OwnerId ?? 0);
            if ($ownerId > 0) {
                $ownerIds[$ownerId] = $ownerId;
            }
        }

        if (empty($ownerIds)) {
            return [];
        }

        $memberships = $this->groupBrandingProvider->GetBrandingMemberships(array_values($ownerIds));
        $brandingByOwner = (new \LibreBooking\Application\Groups\GroupBrandingResolver())->resolve($memberships);
        $hasLogo = false;
        foreach ($brandingByOwner as $branding) {
            if ($branding['logoFileName'] !== null) {
                $hasLogo = true;
                break;
            }
        }
        if ($hasLogo) {
            $logoStorage = new \LibreBooking\Application\Groups\GroupLogoStorage((new ImageUploadDirectory())->GetDirectory());
            foreach ($brandingByOwner as &$branding) {
                if ($branding['logoFileName'] !== null && !$logoStorage->exists($branding['logoFileName'])) {
                    $branding['logoFileName'] = null;
                }
            }
            unset($branding);
        }

        return $brandingByOwner;
    }

    /**
     * Build a public-safe display record so hidden owner or meeting details
     * cannot leak through group branding while the browser is shared.
     *
     * @param ReservationListItem $reservation
     * @param array<int, array{groupId: int, name: string, logoFileName: ?string, initials: string}> $brandingByOwner
     * @return array<string, mixed>
     */
    private function CreatePublicReservationData(ReservationListItem $reservation, array $brandingByOwner)
    {
        $item = $reservation->ReservedItem();
        $view = new ReservationView();
        $view->ReferenceNumber = $reservation->ReferenceNumber();
        $view->OwnerId = $item->OwnerId ?? null;
        $view->StartDate = $reservation->StartDate();
        $view->EndDate = $reservation->EndDate();
        $view->ResourceId = $reservation->ResourceId();

        $publicSession = new NullUserSession();
        $canViewDetails = $this->privacyFilter->CanViewDetails($publicSession, $view, $view->OwnerId);
        $canViewOwner = $this->privacyFilter->CanViewUser($publicSession, $view, $view->OwnerId);
        $ownerId = (int)($item->OwnerId ?? 0);
        $showBranding = $canViewDetails && $canViewOwner && isset($brandingByOwner[$ownerId]);

        return [
            'startDate' => $reservation->StartDate(),
            'endDate' => $reservation->EndDate(),
            'startTimestamp' => $reservation->StartDate()->Timestamp(),
            'endTimestamp' => $reservation->EndDate()->Timestamp(),
            'title' => $canViewDetails ? ($reservation->GetTitle() ?: Resources::GetInstance()->GetString('NoTitleLabel')) : Resources::GetInstance()->GetString('Reserved'),
            'ownerName' => $canViewOwner ? (string)$reservation->GetUserName() : null,
            'group' => $showBranding ? $brandingByOwner[$ownerId] : null,
            'checkedIn' => isset($item->CheckinDate) && $item->CheckinDate->ToString() !== '',
            'referenceNumber' => $reservation->ReferenceNumber(),
        ];
    }
}

class ReservationResultCollector implements IReservationSaveResultsView
{
    /**
     * @var string[]
     */
    public $Warnings;

    /**
     * @var bool
     */
    public $Succeeded;

    /**
     * @var string[]
     */
    public $Errors;

    /**
     * @param bool $succeeded
     */
    public function SetSaveSuccessfulMessage($succeeded)
    {
        $this->Succeeded = $succeeded;
    }

    /**
     * @param array|string[] $errors
     */
    public function SetErrors($errors)
    {
        $this->Errors = $errors;
    }

    /**
     * @param array|string[] $warnings
     */
    public function SetWarnings($warnings)
    {
        $this->Warnings = $warnings;
    }

    /**
     * @param array|string[] $messages
     */
    public function SetRetryMessages($messages)
    {
    }

    /**
     * @param bool $canBeRetried
     */
    public function SetCanBeRetried($canBeRetried)
    {
    }

    /**
     * @param ReservationRetryParameter[] $retryParameters
     */
    public function SetRetryParameters($retryParameters)
    {
    }

    /**
     * @return ReservationRetryParameter[]
     */
    public function GetRetryParameters()
    {
        return [];
    }

    /**
     * @param bool $canJoinWaitlist
     */
    public function SetCanJoinWaitList($canJoinWaitlist)
    {
        // no-op
    }
}
