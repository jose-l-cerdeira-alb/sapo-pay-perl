<?php


use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Reference;

$container = new ContainerBuilder();


$container->register("broker.notifier",'\Pay\Utils\Broker')
          ->setArguments(array(
            array("server"=>"%broker.notifier.server%","port"=>"%broker.notifier.port%", "queue" => "%broker.notifier.queue%")
          ));

$container->register("smarty",'\Pay\Smarty');



$container->register("logger",'\Pay\Log\Logger')
    ->addArgument(array( "file"=>"%logger.output%"));


return $container;
