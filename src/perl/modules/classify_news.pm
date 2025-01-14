#package classify_news;

use 5.010001;
use strict;
use warnings;
use Exporter;

use File::Basename;
use lib dirname (__FILE__) . "/";

#My modules
use check_news_format;
use check_artifacts;
use check_blacklist;
use news_subject_classification;

our @ISA= qw( Exporter );

# these CAN be exported.
our @EXPORT_OK = qw(classify_news);

# these are exported by default.
our @EXPORT = qw(classify_news);

#Classify news in serious or not serious. Returns 0 for a serious news and 1 for a not serious news
sub classify_news{

    my @inputs = @_;

    #Arguments: path news text file [blacklist text file [curse words text file]] 
    if ((scalar (@inputs) < 1) || (scalar (@inputs) > 3) ){
        print "Incorrect input\n";
        print "Try: classify_news (<path to news text file> [path to blacklist text file] [curse words text file]) \n";
        print "NOTE: you MUST enter a news text file written in PORTUGUESE!\n\n";
        return -16;
    }

    #Checking if the news is on the right format
    my $return_value;
    if (($return_value = check_news_format ($inputs[0])) < 0) {
        print "News text file $inputs[0] in wrong format! Check documentation at https://github.com/JoltLeo/News_analyser \n";
        return $return_value;
    }



    #Determining the news subject
    my $news_subject = classify_subject ($inputs[0]);
    

    #Checking if author or source is on the blacklist
    my @blacklist;

    # @blacklist (0, 0) good and @blacklist (n, n) bad
    if (scalar (@inputs) >= 2){
        @blacklist = (check_author_and_source($inputs[0], $inputs[1], 4),check_author_and_source($inputs[0], $inputs[1], 4));  # (author, source)
    }
    else {
        #Use default blacklist text file
        @blacklist = (check_author_and_source($inputs[0], "blacklist.txt", 4),check_author_and_source($inputs[0], "blacklist.txt", 4));
        print "\nUsing default text file for blacklist\n";
    }

    #Cheking emoticons, first person, upper to lower case ratio and curse words 
    my @artifacts; 
    if (scalar (@inputs) == 3){
        @artifacts = final_classifier ($inputs[0], $inputs[2]); 
    }
    else {
        #Use default blacklist text file
        @artifacts = final_classifier ($inputs[0], "curse_words.txt"); 
        print "\nUsing default text file for curse words\n";
    }

    print "\nThe $inputs[0] subject is ",$news_subject, ".\n";
    print "In $inputs[0], there are:\n\n",$blacklist[0] == 0 ? "The author is NOT on the blacklist;\n":"The author is on the blacklist;\n", $blacklist[1] == 0 ?"The sourcer is NOT on the blacklist;\n": "The source is on the blacklist;\n"; 
    print $artifacts[0], " emoticons;\n", $artifacts[1], " first person;\n", $artifacts[2], " upper to lower case ratio;\n", $artifacts[3], " curse words;\n",$artifacts[4]," superlatives\n\n"; 


    #Author or source on blacklist means that the news is not serious
    if ($blacklist[0] != 0){
        print "\nThe author is on the blacklist, so the $inputs[0] is not serious.\n";
        return 1;
    }

    if ($blacklist[1] != 0){
        print "\nThe source is on the blacklist, so the $inputs[0] is not serious.\n";
        return 1;
    }

    #Defining grades for the final classification (serious or not serious)
    my @grades;

    if ($news_subject eq "celebrity"){
        #Only upper to lower case ratio and curse words matter
        @grades = ($artifacts[2], $artifacts[3]);
        if (($grades[0] > 0.056) || ($grades[1] > 0)){
            print "\nThis celebrity news $inputs[0] is NOT serious.\n\n";
            return 1;
        }
        print "\nThis celebrity news $inputs[0] is serious.\n\n";
        return 0
    }
    elsif ($news_subject eq "economy"){
        #Only emoticons, first person, upper to lower case ratio and curse words matter
        @grades = @artifacts;
        if (($grades[0] > 0) || ($grades[1] > 3) || ($grades[2] > 0.056) || ($grades[3] > 0)){
            print "\nThis economy news $inputs[0] is NOT serious.\n\n";
            return 1;
        }
        print "\nThis economy news is $inputs[0] serious.\n\n";
        return 0
    }
    elsif ($news_subject eq "politics"){
        #Only emoticons, upper to lower case ratio and curse words matter
        @grades = ($artifacts[0], $artifacts[2], $artifacts[3]);
        if (($grades[0] > 0) || ($grades[1] > 0.06) || ($grades[2] > 0)){
            print "\nThis politics news $inputs[0] is NOT serious.\n\n";
            return 1;
        }
        print "\nThis politics news $inputs[0] is serious.\n\n";
        return 0
    }
    elsif ($news_subject eq "science"){
        #Only emoticons, first person, upper to lower case ratio and curse words matter
        @grades = @artifacts;
        if (($grades[0] > 0) || ($grades[1] > 4) || ($grades[2] > 0.052) || ($grades[3] > 0)){
            print "\nThis science news $inputs[0] is NOT serious.\n\n";
            return 1;
        }
        print "\nThis science news $inputs[0] is serious.\n\n";
        return 0

    }
    else{ #sports
        #Only emoticons, upper to lower case ratio and curse words matter
        @grades = ($artifacts[0], $artifacts[2], $artifacts[3]);
        if (($grades[0] > 0) || ($grades[1] > 0.056) || ($grades[2] > 0)){
            print "\nThis sports news $inputs[0] is NOT serious.\n\n";
            return 1;
        }
        print "\nThis sports news $inputs[0] is serious.\n\n";
        return 0
    }
    return -17;
}

