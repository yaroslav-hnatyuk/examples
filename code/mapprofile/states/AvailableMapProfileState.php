<?php
namespace frontend\service\mapprofile\states;

use common\service\mapprofile\interfaces\iTeamManagerMapProfile;
use common\service\mapprofile\BaseMapProfileState;
use common\models\mapprofile\MapProfile;
use yii\web\ServerErrorHttpException;

class AvailableMapProfileState extends BaseMapProfileState implements iTeamManagerMapProfile
{

    public function addToList(MapProfile $mapProfile, $teamId = null)
    {
        return $this->getTeamManagerHelper()->addToList($mapProfile, $teamId);
    }

    public function assign(MapProfile $mapProfile, $userId)
    {
        throw new ServerErrorHttpException("Please add to list this Map Profile.");
    }

}