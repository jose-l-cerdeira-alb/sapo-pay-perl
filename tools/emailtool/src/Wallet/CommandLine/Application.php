<?php
/**
 *
 * Project : Meo Wallet
 * User    : Luis Santos <luis.santos@telecom.pt>
 * Date    : 12/16/13
 * Time    : 7:13 PM
 * 
 *
 *
 */

namespace Wallet\CommandLine;


use Symfony\Component\Config\FileLocator;
use Symfony\Component\DependencyInjection\ContainerAwareInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;
use Symfony\Component\DependencyInjection\Loader\YamlFileLoader;
use Wallet\CommandLine\Commands\EmailSender;

class Application extends \Symfony\Component\Console\Application  implements ContainerAwareInterface {


    const VERSION = '0.1';

    /**
     * @var ContainerInterface
     */
    private $container;




    public function __construct()
    {

        parent::__construct('Wallet Tool', self::VERSION);

        $this->loadContainerDefinitions();


        \Pay\Log\Logger::setInstance($this->getContainer()->get("logger"));



        $this->add(new EmailSender($this->getContainer()->get('broker.notifier'),$this->getContainer()->get("smarty")));

    }


    private function loadContainerDefinitions()
    {
        $configDirectories = array(
            __DIR__ . '/../../../config'
        );

        $container = include __DIR__ . '/container.php';

        $loader = new YamlFileLoader($container, new FileLocator($configDirectories));
        $loader->load('parameters.yaml');

        $this->setContainer($container);
    }

    /**
     * Sets the Container.
     *
     * @param ContainerInterface|null $container A ContainerInterface instance or null
     *
     * @api
     */
    public function setContainer(ContainerInterface $container = null)
    {
        $this->container = $container;
    }

    /**
     * @return \Symfony\Component\DependencyInjection\ContainerInterface
     */
    public function getContainer()
    {
        return $this->container;
    }


}