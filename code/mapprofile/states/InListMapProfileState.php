<?php
namespace frontend\service\mapprofile\states;

use common\service\mapprofile\interfaces\iTeamManagerMapProfile;
use common\service\mapprofile\BaseMapProfileState;
use common\models\mapprofile\MapProfile;
use yii\web\ServerErrorHttpException;

class InListMapProfileState extends BaseMapProfileState implements iTeamManagerMapProfile
{

    public function addToList(MapProfile $mapProfile, $teamId = null)
    {
        throw new ServerErrorHttpException("You can not move this Map Profile.");
    }

    public function removeFromList(MapProfile $mapProfile, $teamId = null)
    {
        return $this->getTeamManagerHelper()->removeFromList($mapProfile, $teamId);
    }

    public function assign(MapProfile $mapProfile, $userId)
    {
        return $this->getTeamManagerHelper()->assign($mapProfile, $userId);
    }

    public function unassign(MapProfile $mapProfile, $userId)
    {
        return $this->getTeamManagerHelper()->unassign($mapProfile, $userId);
    }
}