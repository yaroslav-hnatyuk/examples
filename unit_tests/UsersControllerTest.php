<?php
namespace Api\Test\TestCase\Controller\V1;

use Api\Test\Fixture\GroupsFixture;
use Api\Test\Fixture\StatusesFixture;
use Api\Test\Fixture\UsersFixture;
use Cake\I18n\Time;
use Cake\Utility\Text;

/**
 * Api\Controller\V1\UsersController Test Case
 */
class UsersControllerTest extends BaseControllerTest
{

    /**
     * @var string
     */
    private $userId = null;

    /**
     * Fixtures
     *
     * @var array
     */
    public $fixtures = [
        'Users' => 'plugin.api.users',
        'Credentials' => 'plugin.api.credentials',
        'Groups' => 'plugin.api.groups',
        'Logins' => 'plugin.api.logins',
        'Statuses' => 'plugin.api.statuses'
    ];

    /**
     * @inheritdoc
     */
    public function setUp()
    {
        parent::setUp();
        $this->userId = UsersFixture::USER_ID;
    }

    /**
     * Test index method
     *
     * @return void
     */
    public function testIndex()
    {
        $this->get("/api/v1/users.json");
        $this->assertResponseError();
    }

    /**
     * Test view method
     *
     * @return void
     */
    public function testView()
    {
        $this->get("/api/v1/users/{$this->userId}.json");
        $this->assertResponseOk();
        $response = $this->assertResponse();

        $actual = $response['data'];
        $actual['created'] = (new Time($actual['created']))->format('Y-m-d H:i:s');
        $actual['modified'] = (new Time($actual['modified']))->format('Y-m-d H:i:s');

        $expected = $this->getExpectedResponse();

        $this->assertEquals($expected, $actual);
    }

    /**
     * Test add method
     *
     * @param bool $expectedError
     * @param array $params
     *
     * @dataProvider saveUserDataProvider
     *
     */
    public function testAdd(
        $expectedError = false,
        $params = []
    )
    {
        $this->post(
            "/api/v1/users.json",
            [
                'first_name' => $params['first_name'],
                'last_name' => $params['last_name'],
                'email' => $params['email'],
                'password' => $params['password'],
                'accept_terms' => $params['accept_terms']
            ]
        );

        if ($expectedError) {
            $this->assertResponseError();
        } else {
            $this->assertResponseOk();
            $response = $this->assertResponse();

            $actual = $response['data'];
            $this->assertSavedUser($params, $actual);
        }

    }

    /**
     * Test edit method
     *
     * @param bool $expectedError
     * @param array $params
     *
     * @dataProvider saveUserDataProvider
     *
     */
    public function testEdit(
        $expectedError = false,
        $params = []
    )
    {
        $this->patch(
            "/api/v1/users/{$this->userId}.json",
            [
                'first_name' => $params['first_name'],
                'last_name' => $params['last_name'],
                'email' => $params['email'],
                'password' => $params['password']
            ]
        );

        if ($expectedError) {
            $this->assertResponseError();
        } else {
            $response = $this->assertResponse();
            $actual = $response['data'];
            $this->assertSavedUser($params, $actual);
        }
    }

    /**
     * Test login method
     *
     * @param bool $expectedError
     * @param $userName
     * @param $password
     *
     * @dataProvider loginDataProvider
     */
    public function testLogin(
        $expectedError = false,
        $userName,
        $password
    )
    {
        $this->post(
            "/api/v1/users/login.json",
            [
                'username' => $userName,
                'password' => $password
            ]
        );

        if ($expectedError) {
            $this->assertResponseError();
        } else {
            $this->assertResponseOk();
            $response = $this->assertResponse();

            $actual = $response['data'];
            unset($actual['logins'], $actual['status'], $actual['group']);
            $actual['created'] = (new Time($actual['created']))->format('Y-m-d H:i:s');
            $actual['modified'] = (new Time($actual['modified']))->format('Y-m-d H:i:s');

            $expected = $this->getExpectedResponse();
            unset($expected['is_facebook_linked']);

            $this->assertEquals($expected, $actual);
        }

    }

    /**
     * Test login method
     *
     * @return void
     */
    public function testAvatar()
    {
        $this->post("/api/v1/users/avatar/{$this->userId}.json");

        $this->assertResponseOk();
        $response = $this->assertResponse();

        $actual = $response['data'];
        $actual['created'] = (new Time($actual['created']))->format('Y-m-d H:i:s');
        $actual['modified'] = (new Time($actual['modified']))->format('Y-m-d H:i:s');
    }

    /**
     * Test delete method
     *
     * @param $userId
     * @param bool $invalid
     *
     * @dataProvider deleteDataProvider
     */
    public function testDelete($userId, $invalid = false)
    {
        $this->delete("/api/v1/users/{$userId}.json");

        if ($invalid) {
            $this->assertResponseError();
        } else {
            $this->assertResponseOk();
        }
    }

    /**
     * @return array
     */
    public function saveUserDataProvider()
    {
        return [
            //Valid data
            [
                false,                                  //Expected Error
                [
                    'first_name' => 'UT-FirstName',     //First name
                    'last_name' => 'UT-LastName',       //Last name
                    'email' => 'ut.user@gameiq.net',    //Email
                    'password' => 'utpass%123',         //Password
                    'accept_terms' => 1,                //Accept terms
                ]
            ],
            //Empty email
            [
                true,                                   //Expected Error
                [
                    'first_name' => 'UT-FirstName',     //First name
                    'last_name' => 'UT-LastName',       //Last name
                    'email' => '',                      //Email
                    'password' => 'utpass%123',         //Password
                    'accept_terms' => 1,                //Accept terms
                ]
            ]
        ];
    }

    /**
     * @return array
     */
    public function loginDataProvider()
    {
        return [
            //Expected Error,   User Name,                  Password
            [false,             UsersFixture::USER_EMAIL,   UsersFixture::USER_PASSWORD], //Valid data
            [true,              'INVALID',                  UsersFixture::USER_PASSWORD], //Invalid username
            [true,              UsersFixture::USER_EMAIL,   'INVALID'],                   //Invalid password
            [true,              null,                       UsersFixture::USER_PASSWORD], //Empty username
            [true,              UsersFixture::USER_EMAIL,   null]                         //Empty password
        ];
    }

    /**
     * @return array
     */
    public function deleteDataProvider()
    {
        return [
            //User ID               , is ID invalid
            [UsersFixture::USER_ID, false], //valid User ID
            [Text::uuid(),          true],  //unexisting UUID
            [11111,                 true],  //invalid ID (numeric)
            ['INVALID',             true],  //invalid ID (string)
            [null,                  true]   //invalid ID (null)
        ];
    }

    /**
     * @param $params
     * @param $user
     */
    private function assertSavedUser($params, $user)
    {
        $this->assertEquals($params['first_name'], $user['first_name']);
        $this->assertEquals($params['last_name'], $user['last_name']);
        $this->assertEquals($params['email'], $user['email']);
        $this->assertEquals(StatusesFixture::USER_ACTIVE, $user['status_id']);
        $this->assertEquals(GroupsFixture::GROUP_USERS, $user['group_id']);
    }

    /**
     * @return mixed
     */
    private function getExpectedResponse()
    {
        $expected = (new UsersFixture())->records[0];
        //$expected['is_facebook_linked'] = '1';
        $expected['full_name'] = $expected['first_name'] . ' ' . $expected['last_name'];
        $expected= ['is_facebook_linked'=>'1']+$expected;

        unset($expected['password'], $expected['deleted']);


        return $expected;
    }
}
