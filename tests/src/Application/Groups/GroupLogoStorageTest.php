<?php

declare(strict_types=1);

namespace LibreBooking\Tests\Application\Groups;

use InvalidArgumentException;
use LibreBooking\Application\Groups\GroupLogoStorage;
use TestBase;

class GroupLogoStorageTest extends TestBase
{
    private string $directory;

    public function setUp(): void
    {
        parent::setUp();
        $this->directory = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'lb-group-logo-' . bin2hex(random_bytes(8));
        mkdir($this->directory, 0700, true);
    }

    public function tearDown(): void
    {
        foreach (glob($this->directory . DIRECTORY_SEPARATOR . '*') ?: [] as $file) {
            if (is_file($file)) {
                unlink($file);
            }
        }
        rmdir($this->directory);
        parent::tearDown();
    }

    public function testStoresImageWithGeneratedSafeNameAndDeletesIt(): void
    {
        $source = $this->directory . DIRECTORY_SEPARATOR . 'upload.tmp';
        file_put_contents($source, base64_decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
            true
        ));

        $storage = new GroupLogoStorage($this->directory);
        $this->assertFalse($storage->exists('group-logo-0123456789abcdef0123456789abcdef.png'));
        $fileName = $storage->store($source);

        $this->assertMatchesRegularExpression('/\\Agroup-logo-[a-f0-9]{32}\\.png\\z/', $fileName);
        $this->assertFileExists($this->directory . DIRECTORY_SEPARATOR . $fileName);
        $this->assertTrue($storage->exists($fileName));

        $storage->delete($fileName);
        $this->assertFileDoesNotExist($this->directory . DIRECTORY_SEPARATOR . $fileName);
        $this->assertFalse($storage->exists($fileName));
    }

    public function testRejectsNonImageAndOversizedFiles(): void
    {
        $source = $this->directory . DIRECTORY_SEPARATOR . 'upload.tmp';
        $storage = new GroupLogoStorage($this->directory);
        file_put_contents($source, '<svg xmlns="http://www.w3.org/2000/svg"></svg>');
        $this->expectException(InvalidArgumentException::class);
        $storage->store($source);
    }

    public function testRejectsFilesOverTwoMib(): void
    {
        $source = $this->directory . DIRECTORY_SEPARATOR . 'upload.tmp';
        file_put_contents($source, str_repeat('x', GroupLogoStorage::MAX_FILE_SIZE + 1));

        $this->expectException(InvalidArgumentException::class);
        (new GroupLogoStorage($this->directory))->store($source);
    }
}
