<?php

declare(strict_types=1);

namespace LibreBooking\Application\Groups;

final class GroupBrandingResolver
{
    private const LOGO_FILENAME_PATTERN = '/\Agroup-logo-[a-f0-9]{32}\.(?:png|jpg|webp)\z/';

    /**
     * Resolve unambiguous owner memberships into public-safe group branding.
     *
     * @param array<int, array<string, mixed>> $membershipRows
     * @return array<int, array{groupId: int, name: string, logoFileName: ?string, initials: string}>
     */
    public function resolve(array $membershipRows): array
    {
        $owners = [];
        foreach ($membershipRows as $row) {
            $ownerId = (int)($row['user_id'] ?? 0);
            $groupId = (int)($row['group_id'] ?? 0);
            if ($ownerId < 1 || $groupId < 1 || !isset($row['name'])) {
                continue;
            }

            $owners[$ownerId]['groups'][$groupId] = [
                'groupId' => $groupId,
                'name' => (string)$row['name'],
                'logoFileName' => $this->safeLogoFileName($row['logo_filename'] ?? null),
            ];
            $owners[$ownerId]['preferredGroupId'] = empty($row['display_group_id'])
                ? null
                : (int)$row['display_group_id'];
        }

        $resolved = [];
        foreach ($owners as $ownerId => $owner) {
            $groups = $owner['groups'];
            $group = null;
            if (count($groups) === 1) {
                $group = reset($groups);
            } elseif (!empty($owner['preferredGroupId']) && isset($groups[$owner['preferredGroupId']])) {
                $group = $groups[$owner['preferredGroupId']];
            }

            if ($group !== null) {
                $group['initials'] = $this->initials($group['name']);
                $resolved[(int)$ownerId] = $group;
            }
        }

        return $resolved;
    }

    private function safeLogoFileName($fileName): ?string
    {
        if (!is_string($fileName) || preg_match(self::LOGO_FILENAME_PATTERN, $fileName) !== 1) {
            return null;
        }

        return $fileName;
    }

    private function initials(string $name): string
    {
        $words = preg_split('/\s+/u', trim($name), -1, PREG_SPLIT_NO_EMPTY);
        if (empty($words)) {
            return '';
        }

        $first = mb_substr($words[0], 0, 1, 'UTF-8');
        $last = count($words) > 1 ? mb_substr($words[count($words) - 1], 0, 1, 'UTF-8') : '';
        return mb_strtoupper($first . $last, 'UTF-8');
    }
}
