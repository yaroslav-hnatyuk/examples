<?php
namespace Api\Test\TestCase\Controller\V1;

use Api\Test\Fixture\SchedulesFixture;
use Api\Test\Fixture\StoreImagesFixture;
use Api\Test\Fixture\StoresFixture;
use Cake\I18n\Time;
use Cake\ORM\TableRegistry;
use Cake\Utility\Text;

/**
 * Api\Controller\V1\StoresController Test Case
 */
class StoresControllerTest extends BaseControllerTest
{

    /**
     * Fixtures
     *
     * @var array
     */
    public $fixtures = [
        'Users' => 'plugin.api.users',
        'Credentials' => 'plugin.api.credentials',
        'Groups' => 'plugin.api.groups',
        'Statuses' => 'plugin.api.statuses',
        'Favorites' => 'plugin.api.favorites',
        'Schedules' => 'plugin.api.schedules',
        'StoreImages' => 'plugin.api.store_images',
        'Subscriptions' => 'plugin.api.subscriptions',
        'Stores' => 'plugin.api.stores'
    ];

    /**
     * Test index method
     *
     * @param $expectedStoreId
     * @param bool $expectedError
     * @param $latitude
     * @param $longitude
     * @param $distance
     * @param $category
     * @param $text
     *
     * @dataProvider indexDataProvider
     */
    public function testIndex(
        $expectedStoreId = null,
        $expectedError = false,
        $latitude,
        $longitude,
        $distance,
        $category = null,
        $text = null
    )
    {
        $store = TableRegistry::get('Api.Stores')->find('locate', [
            'lat' => $latitude,
            'lng' => $longitude,
            'dst' => $distance,
            'cat' => $category,
            'txt' => $text
        ]);


        $store = $store ? $store->first() : null;
        $store = $store ? $store->toArray() : null;

        if ($expectedError) {
            $this->assertEmpty($store);
        } else {
            $this->assertNotEmpty($store);
            $expectedStore = (new StoresFixture())->records[$expectedStoreId];

            $this->assertEquals($expectedStore['id'], $store['id']);
            $this->assertEquals($expectedStore['category_id'], $store['category_id']);
            $this->assertEquals($expectedStore['status_id'], $store['status_id']);
            $this->assertEquals($expectedStore['name'], $store['name']);
            $this->assertEquals($expectedStore['checkin_expiration'], $store['checkin_expiration']);
            $this->assertEquals($expectedStore['latitude'], $store['latitude']);
            $this->assertEquals($expectedStore['address'], $store['address']);
            $this->assertEquals($expectedStore['city'], $store['city']);
            $this->assertEquals($expectedStore['state'], $store['state']);
            $this->assertEquals($expectedStore['zip'], $store['zip']);
        }
    }

    /**
     * Test view method
     *
     * @param bool $expectedError
     * @param $storeId
     *
     * @dataProvider viewDataProvider
     */
    public function testView($expectedError = false, $storeId)
    {
        $this->get("/api/v1/stores/{$storeId}.json");

        if ($expectedError) {
            $this->assertResponseError();
        } else {
            $this->assertResponseOk();
            $response = $this->assertResponse();

            $this->assertNotEmpty($response['data']);
            $this->assertInternalType('array', $response['data']);

            $store = $response['data'];
            $expectedStore = (new StoresFixture())->records[$storeId];
            $expectedStore['is_favorite'] = true;
            $expectedStore['is_subscribed'] = true;

            $this->assertNotEmpty($store['schedules']);
            $this->assertNotEmpty($store['store_images']);
            $this->assertCount(1, $store['schedules']);
            $this->assertCount(1, $store['store_images']);

            $this->assertSchedule(current($store['schedules']), $storeId);
            $this->assertStoreImage(current($store['store_images']), $storeId);

            unset($store['schedules'], $store['store_images'], $store['user']);
            $this->assertEquals($expectedStore, $store);
        }
    }

    /**
     * @return array
     */
    public function indexDataProvider()
    {
        return [
            //Expected store ID,        Expected error,   Latitude,   Longitude,      Distance,   Category,   Text
            [StoresFixture::STORE_ID,   false,            33.15,      -117.35,        3,          1,          null],     //success
            [StoresFixture::STORE_ID,   false,            33.15,      -117.35,        3,          null,       null],     //success
            [StoresFixture::STORE_ID,   false,        33.150001,  -117.350002,        3,          null,       null],     //success
            [StoresFixture::STORE_ID,   false,            33.15,      -117.35,        0,          null,       null],     //success
            [StoresFixture::STORE_ID2,  false,            43.15,      -107.35,        5,          1,          null],     //success
            [StoresFixture::STORE_ID2,  false,            43.15,      -107.35,        5,          1,          null],     //success
            [StoresFixture::STORE_ID2,  false,            43.15,      -107.35,        5,          null,       null],     //success
            [StoresFixture::STORE_ID2,  false,         43.15001,  -107.350001,        5,          null,       null],     //success
            [StoresFixture::STORE_ID2,  false,            43.15,      -107.35,        0,          null,       null],     //success
            [StoresFixture::STORE_ID2,  true,             43.15,       107.35,        5,          null,       null],     //fail
            [StoresFixture::STORE_ID2,  true,            -43.15,      -107.35,        5,          1,          null],     //fail
            [StoresFixture::STORE_ID2,  true,                  1,           2,        5,          1,          null],     //fail
            [StoresFixture::STORE_ID2,  true,                 -1,           0,        5,          1,          null],     //fail
        ];
    }

    /**
     * @return array
     */
    public function viewDataProvider()
    {
        return [
            //Expected error,   Store ID
            [false,             StoresFixture::STORE_ID],  //valid
            [true,              Text::uuid()],             //invalid (unexisting ID)
            [true,              736763476743],             //invalid (numeric ID)
            [true,              'INVALID__!']              //invalid (string ID)
        ];
    }

    /**
     * @param $schedule
     * @param $storeId
     */
    private function assertSchedule($schedule, $storeId)
    {
        $schedule['start_time'] = (new Time($schedule['start_time']))->format('H:i:s');
        $schedule['end_time'] = (new Time($schedule['end_time']))->format('H:i:s');

        $expectedSchedule = (new SchedulesFixture())->records[$storeId];
        unset($expectedSchedule['created'], $expectedSchedule['modified']);

        $this->assertEquals($expectedSchedule, $schedule);
    }

    private function assertStoreImage($storeImage, $storeId)
    {
        $storeImage['created'] = (new Time($storeImage['created']))->format('Y-m-d H:i:s');;
        $storeImage['modified'] = (new Time($storeImage['modified']))->format('Y-m-d H:i:s');;
        $this->assertEquals((new StoreImagesFixture())->records[$storeId], $storeImage);
    }
}
