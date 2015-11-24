<?php
namespace common\service\mapprofile\interfaces;

use common\models\mapprofile\MapProfile;

interface iTeamManagerMapProfile
{
    public function addToList(MapProfile $mapProfile, $teamId);

    public function assign(MapProfile $mapProfile, $userId);

}