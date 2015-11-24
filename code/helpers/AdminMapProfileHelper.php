<?php
namespace common\service\mapprofile\helpers;

use common\models\mapprofile\MapProfile;
use common\models\mapprofile\MapProfileForm;
use common\service\mapprofile\interfaces\iAdminMapProfile;
use common\service\mapprofile\MapProfileService;

class AdminMapProfileHelper implements iAdminMapProfile
{

    public function update(MapProfile $mapProfile, MapProfileForm $mapProfileForm)
    {
        return MapProfileService::getInstance()->updateMapProfile($mapProfile, $mapProfileForm);
    }

    public function delete(MapProfile $mapProfile)
    {
        $mapProfile->delete();
        return $mapProfile;
    }
}