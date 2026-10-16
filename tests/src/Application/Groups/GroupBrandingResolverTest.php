<?php

declare(strict_types=1);

namespace LibreBooking\Tests\Application\Groups;

use LibreBooking\Application\Groups\GroupBrandingResolver;
use TestBase;

class GroupBrandingResolverTest extends TestBase
{
    private GroupBrandingResolver $resolver;

    public function setUp(): void
    {
        parent::setUp();
        $this->resolver = new GroupBrandingResolver();
    }

    public function testUsesTheOnlyCurrentOwnerGroup(): void
    {
        $resolved = $this->resolver->resolve([
            $this->membership(17, 4, 'Libre Booking', 'group-logo-0123456789abcdef0123456789abcdef.webp', null),
        ]);

        $this->assertSame(4, $resolved[17]['groupId']);
        $this->assertSame('LB', $resolved[17]['initials']);
        $this->assertSame('group-logo-0123456789abcdef0123456789abcdef.webp', $resolved[17]['logoFileName']);
    }

    public function testSingleCurrentMembershipIgnoresStalePreference(): void
    {
        $resolved = $this->resolver->resolve([
            $this->membership(22, 12, 'Operations', null, 99),
        ]);

        $this->assertSame(12, $resolved[22]['groupId']);
    }

    public function testUsesAValidPreferredGroupForMultipleMemberships(): void
    {
        $resolved = $this->resolver->resolve([
            $this->membership(17, 4, 'Finance', null, 9),
            $this->membership(17, 9, 'Research', null, 9),
        ]);

        $this->assertSame(9, $resolved[17]['groupId']);
        $this->assertSame('R', $resolved[17]['initials']);
        $this->assertNull($resolved[17]['logoFileName']);
    }

    public function testOmitsAmbiguousOrRemovedPreferredMemberships(): void
    {
        $resolved = $this->resolver->resolve([
            $this->membership(17, 4, 'Finance', null, null),
            $this->membership(17, 9, 'Research', null, null),
            $this->membership(22, 12, 'Operations', null, 99),
            $this->membership(22, 13, 'Facilities', null, 99),
        ]);

        $this->assertArrayNotHasKey(17, $resolved);
        $this->assertArrayNotHasKey(22, $resolved);
    }

    public function testIgnoresInvalidLogoNamesAndOwnersWithoutMemberships(): void
    {
        $resolved = $this->resolver->resolve([
            $this->membership(17, 4, 'Marketing', '../private.svg', null),
            ['user_id' => 0, 'group_id' => 2, 'name' => 'Invalid'],
        ]);

        $this->assertSame(4, $resolved[17]['groupId']);
        $this->assertNull($resolved[17]['logoFileName']);
        $this->assertSame('M', $resolved[17]['initials']);
        $this->assertCount(1, $resolved);
    }

    /** @return array<string, int|string|null> */
    private function membership(int $ownerId, int $groupId, string $name, ?string $logo, ?int $preferred): array
    {
        return [
            'user_id' => $ownerId,
            'group_id' => $groupId,
            'name' => $name,
            'logo_filename' => $logo,
            'display_group_id' => $preferred,
        ];
    }
}
