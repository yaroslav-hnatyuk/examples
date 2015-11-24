<?php
namespace common\service\mapprofile;

use common\models\User;
use common\service\mapprofile\helpers\AdminMapProfileHelper;
use common\service\mapprofile\helpers\AgentMapProfileHelper;
use common\service\mapprofile\helpers\OfficeManagerMapProfileHelper;
use common\service\mapprofile\helpers\TeamManagerMapProfileHelper;
use yii\web\ServerErrorHttpException;

abstract class BaseMapProfileState
{
    /**
     * @var AgentMapProfileHelper $agentHelper
     */
    private $agentHelper = null;

    /**
     * @var TeamManagerMapProfileHelper $teamManagerHelper
     */
    private $teamManagerHelper = null;

    /**
     * @var AdminMapProfileHelper $adminHelper
     */
    private $adminHelper = null;

    public function __call($name, $arguments)
    {
        throw new ServerErrorHttpException("This action couldn't be performed for current Map Profile state.");
    }

    /**
     * @return AgentMapProfileHelper
     */
    protected function getAgentHelper()
    {
        if (!$this->agentHelper) {
            $this->agentHelper = new AgentMapProfileHelper();
        }

        return $this->agentHelper;
    }

    /**
     * @return TeamManagerMapProfileHelper
     */
    protected function getTeamManagerHelper()
    {
        if (!$this->teamManagerHelper) {
            $this->teamManagerHelper = new TeamManagerMapProfileHelper();
        }

        return $this->teamManagerHelper;
    }

    /**
     * @return AdminMapProfileHelper
     */
    protected function getAdminHelper()
    {
        if (!$this->adminHelper) {
            $this->adminHelper = new AdminMapProfileHelper();
        }

        return $this->adminHelper;
    }
} 