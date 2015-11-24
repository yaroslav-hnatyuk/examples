<?php
namespace common\service\mapprofile\helpers;

use common\models\User;
use common\models\mapprofile\MapProfile;
use common\models\mapprofile\MapProfileAgent;
use common\models\mapprofile\MapProfileTeam;
use common\service\mapprofile\interfaces\iTeamManagerMapProfile;
use yii\web\NotFoundHttpException;
use yii\web\ServerErrorHttpException;

class TeamManagerMapProfileHelper implements iTeamManagerMapProfile
{

    public function addToList(MapProfile $mapProfile, $teamId)
    {
        $mapProfileTeam = new MapProfileTeam();
        $mapProfileTeam->map_profile_id = $mapProfile->id;
        $mapProfileTeam->team_id = $teamId;
        $mapProfileTeam->save();

        return $mapProfileTeam;
    }

    public function assign(MapProfile $mapProfile, $userId)
    {
        $mapProfileAgent = MapProfileAgent::findOne([
            'map_profile_id' => $mapProfile->id,
            'user_id' => $userId
        ]);

        if (!$mapProfileAgent) {
            $mapProfileAgent = new MapProfileAgent();
            $mapProfileAgent->map_profile_id = $mapProfile->id;
            $mapProfileAgent->user_id = $userId;
            $mapProfileAgent->status = MapProfileAgent::NOT_STARTED;
            $mapProfileAgent->save();
        }

        return $mapProfileAgent;

    }

}