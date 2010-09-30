<?php

        $credentials = "your_email_address:your_passwordpassword";
        // just a sample below naturally you need to replace this with the right project and taks ids, as you cannot access these.
        $xml_data = "<request> <notes>qwer</notes> <hours>0.25</hours> <project_id>75406</project_id> <task_id>93182</task_id> <spent_at>Fri, 08 Feb 2008</spent_at> </request>";
        $url = "http://YOURDOMAIN.harvestapp.com/daily/add";

        $headers = array(
            "Content-type: application/xml",
            "Accept: application/xml",
            "Authorization: Basic " . base64_encode($credentials)
        );

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_VERBOSE, 1);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_TIMEOUT, 60);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_USERAGENT, "YOUR DESCRIPTIVE NAME GOES HERE");


        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $xml_data);

        $data = curl_exec($ch);

        if (curl_errno($ch)) {
            print "Error: " . curl_error($ch);
        } else {
            // Show me the result
            var_dump($data);
            curl_close($ch);
        }

?>