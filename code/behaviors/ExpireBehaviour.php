<?php

namespace common\behaviors;

use yii\behaviors\AttributeBehavior;
use yii\db\BaseActiveRecord;


class ExpireBehaviour extends AttributeBehavior
{
    /**
     * @var string the attribute that will receive timestamp value
     * Set this property to false if you do not want to record the expiration time.
     */
    public $expiredAtAttribute = 'expired_at';

    public $value;

    /**
     * @inheritdoc
     */
    public function init()
    {
        parent::init();

        if (empty($this->attributes)) {
            $this->attributes = [
                BaseActiveRecord::EVENT_BEFORE_INSERT => [$this->expiredAtAttribute]
            ];
        }
    }

    /**
     * @inheritdoc
     */
    protected function getValue($event)
    {
        return $this->value;
    }

}
