<?php
namespace common\service\mapprofile\interfaces;

use common\models\mapprofile\MapProfile;

interface iAgentMapProfile
{
    public function start(MapProfile $mapProfile);

    public function complete(MapProfile $mapProfile);

} 