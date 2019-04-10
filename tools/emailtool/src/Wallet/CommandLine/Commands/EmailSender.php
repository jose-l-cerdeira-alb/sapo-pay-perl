<?php
/**
 *
 * Project : Meo Wallet
 * User    : Luis Santos <luis.santos@telecom.pt>
 * Date    : 12/16/13
 * Time    : 7:11 PM
 * 
 *
 *
 */

namespace Wallet\CommandLine\Commands;


use Pay\Log\Logger;
use Pay\Notifications\Manager;
use Pay\Smarty;
use Pay\Utils\Broker;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class EmailSender extends Command {


    /**
     * @var Broker
     */
    protected  $broker;

    /**
     * @var Smarty
     */
    protected  $parser;

    function __construct(Broker $broker,Smarty $smarty)
    {

        parent::__construct();

        $this->setParser($smarty);
        $this->setBroker($broker);
    }

    protected function configure()
    {
        $this
            ->setName('email:send')
            ->setDescription('Sends the email')
            ->addArgument('contactList', InputArgument::REQUIRED, 'Contact list(one email per file)')
            ->addArgument('templateFile', InputArgument::REQUIRED, 'Smarty Template file')
            ->addArgument('subject', InputArgument::OPTIONAL, 'Email subject')
            ->setHelp('The <info>email:send</info> command sends emails');
    }

    public function sendEmail(OutputInterface $output,$contacts,$body,$subject){


        $broker = $this->getBroker();

        $manager = new Manager($broker);

        $output->writeln("Sending.....");

        $fh = fopen($contacts, 'r');

        $total = 0;
        while($contact = fgets($fh)){
            $total++;
        }

        fseek($fh,0);


        $progress = $this->getHelperSet()->get('progress');

        $progress->start($output, $total);

        $errors = 0;
        while($contact = fgets($fh)){

            $mail  =  new \Pay\Notifications\EmailNotification( $contact, $subject ,$body ,array(),"html",$manager);

            $code = $mail->send();

            if(!($code===0)){
              $errors++;
               Logger::log("Error send message to : $contact ($code)");
            }


            $progress->advance();
        }

        $progress->finish();



        fclose($fh);

        $output->writeln("All emails sent");
        if($errors){
            $output->write("<error>Some errors found. Please check the log for more details</error>");
        }



    }

    protected function parseFile($file){

        $smarty = $this->getParser();

        return $smarty->fetch($file);

    }

    protected function execute(InputInterface $input, OutputInterface $output){


        $contact_list_file = $input->getArgument("contactList");
        $smarty_template = $input->getArgument("templateFile");
        $subject = $input->getArgument("subject");

        if(empty($subject)){
            return ;
        }

        if(!$this->isTemplateValid($smarty_template)){
            throw new \InvalidArgumentException('Invalid email template');
        }

        if(!$this->isValidContactFile($contact_list_file)){
            throw new \InvalidArgumentException('Invalid contact file');
        }

        $body = $this->parseFile($smarty_template);



        $this->sendEmail($output,$contact_list_file,$body,$subject);

    }

    protected function isTemplateValid($file){
        return file_exists($file);
    }

    protected function isValidContactFile($file){
        if(!file_exists($file)){
            return false;
        }

        $fh = fopen($file, 'r');

        $n = 1;
        while($line = fgets($fh)){

            if($line){

                $line = trim($line);

                $result = filter_var($line, FILTER_VALIDATE_EMAIL);

                if($result===false){
                    fclose($fh);
                    throw new \InvalidArgumentException("Invalid email format. ($n: $line)");
                }
            }

            $n++;
        }



        fclose($fh);

        return true;

    }

    /**
     * @param \Pay\Utils\Broker $broker
     */
    public function setBroker($broker)
    {
        $this->broker = $broker;
    }

    /**
     * @return \Pay\Utils\Broker
     */
    public function getBroker()
    {
        return $this->broker;
    }

    /**
     * @param \Pay\Smarty $parser
     */
    public function setParser($parser)
    {
        $this->parser = $parser;
    }

    /**
     * @return \Pay\Smarty
     */
    public function getParser()
    {
        return $this->parser;
    }


    /**
     * @see Command
     */
    protected function interact(InputInterface $input, OutputInterface $output)
    {
        if (!$input->getArgument('subject')) {

            $dialog = $this->getHelper('dialog');

            $subject = $dialog->askAndValidate(
                $output,
                'Please insert email subject: ',
                function ($subject) use ($dialog,$output,$input) {
                    if (empty($subject)) {
                        throw new \InvalidArgumentException('Invalid email subject');
                    }

                    if(!$dialog->askConfirmation($output,"<question>Sending email with subject: '$subject' (N/y)</question>",false)){
                        return;
                    }

                    return $subject;
                }
            );
            $input->setArgument('subject', $subject);
        }
    }





}