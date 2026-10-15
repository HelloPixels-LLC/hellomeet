<?php

declare(strict_types=1);

namespace LibreBooking\Application\Groups;

use InvalidArgumentException;
use RuntimeException;

final class GroupLogoStorage
{
    public const MAX_FILE_SIZE = 2097152;
    private const MAX_IMAGE_PIXELS = 10000000;
    private const MAX_IMAGE_DIMENSION = 10000;
    private const FILENAME_PATTERN = '/\Agroup-logo-[a-f0-9]{32}\.(?:png|jpg|webp)\z/';

    public function __construct(private readonly string $directory)
    {
    }

    public function store(string $sourcePath): string
    {
        $sourceSize = @filesize($sourcePath);
        if ($sourceSize === false || $sourceSize < 1 || $sourceSize > self::MAX_FILE_SIZE) {
            throw new InvalidArgumentException('Group logos must be non-empty images no larger than 2 MiB.');
        }

        $contents = @file_get_contents($sourcePath);
        if ($contents === false || $contents === '' || strlen($contents) > self::MAX_FILE_SIZE) {
            throw new InvalidArgumentException('Group logos must be non-empty images no larger than 2 MiB.');
        }

        $image = @getimagesizefromstring($contents);
        if ($image === false || $image[0] < 1 || $image[1] < 1
            || $image[0] > self::MAX_IMAGE_DIMENSION || $image[1] > self::MAX_IMAGE_DIMENSION
            || ($image[0] * $image[1]) > self::MAX_IMAGE_PIXELS) {
            throw new InvalidArgumentException('The uploaded file is not a supported image.');
        }

        $mime = (new \finfo(FILEINFO_MIME_TYPE))->buffer($contents);
        $supportedTypes = [
            IMAGETYPE_PNG => ['image/png', 'png'],
            IMAGETYPE_JPEG => ['image/jpeg', 'jpg'],
            IMAGETYPE_WEBP => ['image/webp', 'webp'],
        ];
        if (!isset($supportedTypes[$image[2]]) || $mime !== $supportedTypes[$image[2]][0]) {
            throw new InvalidArgumentException('Group logos must be PNG, JPEG, or WebP images.');
        }

        if (function_exists('imagecreatefromstring')) {
            $decoded = @imagecreatefromstring($contents);
            if ($decoded === false) {
                throw new InvalidArgumentException('The uploaded image could not be decoded.');
            }
            imagedestroy($decoded);
        }

        if (!is_dir($this->directory) && !@mkdir($this->directory, 0770, true) && !is_dir($this->directory)) {
            throw new RuntimeException('The group logo directory is unavailable.');
        }
        if (!is_writable($this->directory)) {
            throw new RuntimeException('The group logo directory is not writable.');
        }

        $fileName = 'group-logo-' . bin2hex(random_bytes(16)) . '.' . $supportedTypes[$image[2]][1];
        $target = rtrim($this->directory, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $fileName;
        $temporaryPath = tempnam($this->directory, '.group-logo-');
        if ($temporaryPath === false) {
            throw new RuntimeException('A temporary logo file could not be created.');
        }

        try {
            if (file_put_contents($temporaryPath, $contents, LOCK_EX) !== strlen($contents)
                || !@rename($temporaryPath, $target)) {
                throw new RuntimeException('The uploaded logo could not be saved.');
            }
            @chmod($target, 0640);
        } finally {
            if (is_file($temporaryPath)) {
                @unlink($temporaryPath);
            }
        }

        return $fileName;
    }

    public function delete(?string $fileName): void
    {
        if ($fileName === null || !self::isSafeFileName($fileName)) {
            return;
        }

        $path = rtrim($this->directory, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $fileName;
        if (is_file($path)) {
            @unlink($path);
        }
    }

    public function exists(?string $fileName): bool
    {
        if ($fileName === null || !self::isSafeFileName($fileName)) {
            return false;
        }

        $path = rtrim($this->directory, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $fileName;
        return is_file($path) && is_readable($path);
    }

    public static function isSafeFileName(string $fileName): bool
    {
        return preg_match(self::FILENAME_PATTERN, $fileName) === 1;
    }
}
