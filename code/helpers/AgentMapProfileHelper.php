<?php
namespace common\service\mapprofile\helpers;

use common\models\mapprofile\MapProfile;
use common\models\mapprofile\MapProfileAgent;
use common\service\mapprofile\interfaces\iAgentMapProfile;
use yii\web\NotFoundHttpException;
use yii\web\ServerErrorHttpException;

class AgentMapProfileHelper implements iAgentMapProfile
{

    /**
     * @param MapProfile $mapProfile
     * @return MapProfileAgent
     * @throws NotFoundHttpException
     */
    public function start(MapProfile $mapProfile)
    {

        $mapProfileAgent = $this->getMapProfileAgent($mapProfile->id);

        if ($mapProfileAgent->status != MapProfileAgent::STARTED) {
            $mapProfileAgent->status = MapProfileAgent::STARTED;
            $mapProfileAgent->save();
        }

        return $mapProfileAgent;
    }

    /**
     * @param MapProfile $mapProfile
     * @return MapProfileAgent
     * @throws NotFoundHttpException
     */
    public function complete(MapProfile $mapProfile)
    {

        $mapProfileAgent = $this->getMapProfileAgent($mapProfile->id);

        if ($mapProfileAgent->status != MapProfileAgent::COMPLETED) {
            $mapProfileAgent->status = MapProfileAgent::COMPLETED;
            $mapProfileAgent->save();
        }

        return $mapProfileAgent;
    }

    /**
     * @param $mapProfileId
     * @return MapProfileAgent
     * @throws NotFoundHttpException
     */
    private function getMapProfileAgent($mapProfileId)
    {
        $mapProfileAgent = MapProfileAgent::findOne([
            'map_profile_id' => $mapProfileId,
            'user_id' => \Yii::$app->user->id
        ]);

        if (!$mapProfileAgent) {
            throw new NotFoundHttpException("This Map Profile is not available.");
        }

        return $mapProfileAgent;
    }
}