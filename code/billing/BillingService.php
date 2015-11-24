<?php
namespace frontend\service\billing;

use frontend\modules\v1\models\Billing;

class BillingService
{
    /**
     * @var BillingObserver $instance
     */
    private static $instance = null;

    /**
     * @return BillingObserver
     */
    public static function getInstance()
    {
        if (!static::$instance) {
            static::$instance = new static();
        }
        return static::$instance;
    }

    /**
     * @param $userId
     * @param $sum
     * @param $type
     * @throws \Exception
     */
    public function saveOperation($userId, $sum, $type)
    {
        $billingModel = new Billing();
        $billingModel->user_id = $userId;
        $billingModel->sum = $sum;
        $billingModel->type = $type;

        if (!$billingModel->save()) {
            throw new \Exception("Unexpected error. Can't save billing operation.");
        }
    }

    private function __construct() {}
    private function __clone() {}
    private function __sleep() {}
    private function __wakeup() {}
}