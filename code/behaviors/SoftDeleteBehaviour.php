<?php

namespace common\behaviors;

use yii\behaviors\AttributeBehavior;
use yii\db\BaseActiveRecord;


class SoftDeleteBehaviour extends AttributeBehavior
{
    const STATUS_DELETED = 1;
    const IS_DELETED_ATTRIBUTE = 'is_deleted';

    /**
     * @inheritdoc
     */
    public function init()
    {
        parent::init();

        if (empty($this->attributes)) {
            $this->attributes = [
                BaseActiveRecord::EVENT_BEFORE_DELETE => [self::IS_DELETED_ATTRIBUTE]
            ];
        }
    }

    /**
     * @inheritdoc
     */
    protected function getValue($event)
    {
        return self::STATUS_DELETED;
    }

}
