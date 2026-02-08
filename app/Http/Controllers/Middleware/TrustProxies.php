<?php

namespace App\Http\Controllers\Middleware;

use Illuminate\Http\Request;
use Illuminate\Http\Middleware\TrustProxies as Middleware;

class TrustProxies extends Middleware
{

    protected $proxies = '*';
}
