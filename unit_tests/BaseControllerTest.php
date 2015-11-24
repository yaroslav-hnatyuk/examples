<?php
namespace Api\Test\TestCase\Controller\V1;

use Api\Test\Fixture\CredentialsFixture;
use Api\Test\Fixture\GroupsFixture;
use Api\Test\Fixture\StatusesFixture;
use Api\Test\Fixture\UsersFixture;
use Cake\I18n\Time;
use Cake\TestSuite\IntegrationTestCase;
use Cake\Utility\Text;

/**
 * Api\Controller\V1\UsersController Test Case
 */
abstract class BaseControllerTest extends IntegrationTestCase
{

    /**
     * @inheritdoc
     */
    public function setUp()
    {
        parent::setUp();

        $this->configRequest([
            'headers' => [
                'Accept' => 'application/json',
                'GIQ-API-Access-Key' => CredentialsFixture::ACCESS_KEY,
                'GIQ-API-Secret-Key' => CredentialsFixture::SECRET_KEY,
                'GIQ-User-Access-Token' => UsersFixture::USER_TOKEN,
            ]
        ]);

    }

    /**
     * @return mixed
     */
    protected function assertResponse()
    {
        $this->assertNotEmpty($this->_response->body());

        $response = json_decode($this->_response->body(), true);
        $this->assertNotEmpty($response);
        $this->assertInternalType('array', $response);

        return $response;
    }

}
