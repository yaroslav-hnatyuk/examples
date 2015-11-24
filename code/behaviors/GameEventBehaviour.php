<?php

namespace common\behaviors;

use frontend\modules\v1\models\gamification\event\GameActionEvent;
use frontend\modules\v1\models\gamification\event\GamificationEvent;
use yii\base\Behavior;


class GameEventBehaviour extends Behavior
{
    const LISTENER_METHOD = 'handle';

    private $actions = [];

    /**
     * @inheritdoc
     */
    public function init()
    {
        parent::init();
        $this->initEvents();
        $this->addListeners();
    }

    private function initEvents()
    {
        $this->actions = [
            GameActionEvent::ACTION_KNOCK,
            GameActionEvent::ACTION_HOME,
            GameActionEvent::ACTION_BILL,
            GameActionEvent::ACTION_ADD_MAP_PROFILE,
            GameActionEvent::ACTION_CHOOSE_LEVEL
        ];
    }

    private function addListeners()
    {
        foreach ($this->actions as $action) {
            $listeners = GameActionEvent::getInstance()->getActionListeners($action);
            foreach ($listeners as $listener) {
                GamificationEvent::on(static::className(), $action, [$listener, static::LISTENER_METHOD]);
            }
        }
    }

}
