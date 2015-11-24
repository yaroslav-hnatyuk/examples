<?php
namespace frontend\service\mapprofile\states;

use common\service\mapprofile\interfaces\iAgentMapProfile;
use common\service\mapprofile\interfaces\iTeamManagerMapProfile;
use common\service\mapprofile\BaseMapProfileState;
use common\models\mapprofile\MapProfile;
use yii\web\ServerErrorHttpException;

class CompletedMapProfileState extends BaseMapProfileState implements iAgentMapProfile, iTeamManagerMapProfile
{

    public function addToList(MapProfile $mapProfile, $teamId = null)
    {
        throw new ServerErrorHttpException("You can not add to list this Map Profile.");
    }

    public function assign(MapProfile $mapProfile, $userId)
    {
        throw new ServerErrorHttpException("You can not assign this Map Profile.");
    }

    public function start(MapProfile $mapProfile)
    {
        return $this->getAgentHelper()->start($mapProfile);
    }

    public function complete(MapProfile $mapProfile)
    {
        throw new ServerErrorHttpException("You can not complete this Map Profile.");
    }
}