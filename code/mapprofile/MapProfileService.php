<?php
namespace frontend\service\mapprofile;

use common\models\mapprofile\MapProfile;
use common\service\mapprofile\interfaces\iAgentMapProfile;
use common\service\mapprofile\interfaces\iTeamManagerMapProfile;
use yii\base\Exception;
use yii\web\NotFoundHttpException;
use yii\web\ServerErrorHttpException;

class MapProfileService implements iAgentMapProfile, iTeamManagerMapProfile
{

    /**
     * @var iMapProfileClientService $state
     */
    private $state = null;

    protected static $instance = null;

    /**
     * @return MapProfileService
     */
    public static function getInstance()
    {
        if (!static::$instance) {
            static::$instance = new static();
        }
        return static::$instance;
    }

    private function getState(MapProfile $mapProfile)
    {
        if (!$this->state) {
            $this->state = MapProfileStateFactory::getStateInstance($mapProfile);
        }
        return $this->state;
    }

    public function start(MapProfile $mapProfile)
    {
        try {
            $result = $this->getState($mapProfile)->start($mapProfile);
        } catch (Exception $exc) {
            throw new NotFoundHttpException('Unexpected error while processing Map Profile.');
        }

        return $result;
    }

    public function complete(MapProfile $mapProfile)
    {
        try {
            $result = $this->getState($mapProfile)->complete($mapProfile);
        } catch (Exception $exc) {
            throw new NotFoundHttpException('Unexpected error while processing Map Profile.');
        }

        return $result;
    }

    public function addToList(MapProfile $mapProfile, $teamId = null)
    {
        try {
            $result = $this->getState($mapProfile)->addToList($mapProfile, $teamId);
        } catch (Exception $exc) {
            throw new NotFoundHttpException('Unexpected error while processing Map Profile.');
        }

        return $result;
    }

    public function assign(MapProfile $mapProfile, $userId)
    {
        try {
            $result = $this->getState($mapProfile)->assign($mapProfile, $userId);
        } catch (Exception $exc) {
            throw new NotFoundHttpException('Unexpected error while processing Map Profile.');
        }

        return $result;
    }

    public function prepare(MapProfile $mapProfile)
    {
        try {
            $result = $this->getState($mapProfile)->prepare($mapProfile);
        } catch (Exception $exc) {
            throw new NotFoundHttpException('Unexpected error while processing Map Profile.');
        }

        return $result;
    }

    private function __construct()
    {
    }

    private function __clone()
    {
    }

    private function __wakeup()
    {
    }
}