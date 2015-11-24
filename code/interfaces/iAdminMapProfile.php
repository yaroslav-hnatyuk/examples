<?php
namespace common\service\mapprofile\interfaces;

use common\models\mapprofile\MapProfileForm;
use common\models\mapprofile\MapProfile;

interface iAdminMapProfile
{
    public function update(MapProfile $mapProfile, MapProfileForm $mapProfileForm);

    public function delete(MapProfile $mapProfile);
}