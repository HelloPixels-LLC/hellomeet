<?php

declare(strict_types=1);

class BookableResourceTest extends TestBase
{
    public function testDisplayRequiresItsOwnFlagAndPublicIdentifier(): void
    {
        $calendarOnly = BookableResource::CreateNew('Room', 1);
        $this->assertFalse($calendarOnly->GetIsDisplayEnabled());

        $calendarOnly->EnableSubscription();
        $this->assertTrue($calendarOnly->GetIsCalendarSubscriptionAllowed());
        $this->assertFalse($calendarOnly->GetIsDisplayEnabled());

        $displayOnly = BookableResource::CreateNew('Room', 1);
        $displayOnly->EnableDisplay();
        $this->assertTrue($displayOnly->GetIsDisplayEnabled());
        $this->assertFalse($displayOnly->GetIsCalendarSubscriptionAllowed());

        $displayOnly->WithPublicId(null);
        $this->assertFalse($displayOnly->GetIsDisplayEnabled());
    }
}
