<?php
namespace frontend\service\mapprofile\states;

use common\models\mapprofile\MapProfile;
use common\models\mapprofile\MapProfileForm;
use common\service\mapprofile\interfaces\iAdminMapProfile;
use common\service\mapprofile\BaseMapProfileState;
use yii\web\ServerErrorHttpException;

class PreparationMapProfileState extends BaseMapProfileState implements iAdminMapProfile
{

    public function update(MapProfile $mapProfile, MapProfileForm $mapProfileForm)
    {
        throw new ServerErrorHttpException('You can not update this Map Profile.');
    }

    public function delete(MapProfile $mapProfile)
    {
        throw new ServerErrorHttpException('You can not delete this Map Profile.');
    }
}