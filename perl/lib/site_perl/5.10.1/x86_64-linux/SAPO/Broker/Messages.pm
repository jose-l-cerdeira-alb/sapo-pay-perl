package SAPO::Broker::Messages;

#convenience module
#import sub modules with every message

use SAPO::Broker::Messages::Accepted;
use SAPO::Broker::Messages::Acknowledge;
use SAPO::Broker::Messages::Authentication;
use SAPO::Broker::Messages::Fault;
use SAPO::Broker::Messages::Message;
use SAPO::Broker::Messages::Notification;
use SAPO::Broker::Messages::Ping;
use SAPO::Broker::Messages::Poll;
use SAPO::Broker::Messages::Pong;
use SAPO::Broker::Messages::Publish;
use SAPO::Broker::Messages::Subscribe;
use SAPO::Broker::Messages::Unsubscribe;
use SAPO::Broker::Messages::Authentication;

1;
