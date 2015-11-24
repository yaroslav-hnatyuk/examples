<?php
namespace frontend\service\mapprofile\states;

use common\service\mapprofile\interfaces\iAgentMapProfile;
use common\service\mapprofile\interfaces\iTeamManagerMapProfile;
use common\service\mapprofile\BaseMapProfileState;
use common\models\mapprofile\MapProfile;
use yii\web\ServerErrorHttpException;

class InProgressMapProfileState extends BaseMapProfileState implements iAgentMapProfile, iTeamManagerMapProfile
{

    public function start(MapProfile $mapProfile)
    {
        throw new ServerErrorHttpException("You can't start this Map Profile. Other user is currently working on a Map Profile.");
    }

    public function complete(MapProfile $mapProfile)
    {
        return $this->getAgentHelper()->complete($mapProfile);
    }

    public function addToList(MapProfile $mapProfile, $teamId = null)
    {
        throw new ServerErrorHttpException("You can't move this Map Profile. Other user is currently working on a Map Profile.");
    }

    public function assign(MapProfile $mapProfile, $userId)
    {
        throw new ServerErrorHttpException("You can't assign this user. Other user is currently working on a Map Profile.");
    }

}