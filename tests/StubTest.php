<?php

declare(strict_types=1);

namespace Tests;

use PHPUnit\Framework\Attributes\CoversNothing;
use PHPUnit\Framework\Attributes\DoesNotPerformAssertions;
use PHPUnit\Framework\Attributes\Small;
use PHPUnit\Framework\Attributes\Test;

/**
 * @internal
 *
 * @no-named-arguments
 */
#[CoversNothing()]
#[Small()]
class StubTest extends TestCase
{
    #[DoesNotPerformAssertions()]
    #[Test()]
    public function test(): void
    {
    }
}
