<#--CHECK FOR ADMIN ROLE-->
<#assign userRoles = (restBuilder().admin(true).liql("SELECT name FROM roles WHERE users.id = '${user.id?c}'").data.items)![]/>
<#assign admin = "false">
<#list userRoles as role>
    <#if role.name == "Administrator">
        <#assign admin = "true" />
    </#if>
</#list>

<#if admin == "true">

    <#--PAGE TITLE-->
    <div class="lia-page-header">
		<h1 class="PageTitle lia-component-common-widget-page-title"><span class="lia-link-navigation lia-link-disabled">Idea Votes Download</span></h1>
	</div>
    <#--PAGE TITLE-->

    <#--BOARD LIST-->
    <#assign boardList = liql("SELECT title, id FROM boards WHERE conversation_style = 'idea'").data.items />

    <ul>
        <#list boardList as board>
            <li>
                <input type="checkbox" name="${board.id}" value="${board.id}" class="board-checkbox-ak">
                <label for="${board.id}">${board.title}</label>
            </li>
        </#list>
    </ul>
    <#--BOARD LIST-->

    <div id="button-row-ak">
        <input type="button" class="lia-button lia-button-primary" value="Generate CSV" id="generate-csv-button-ak">
        <a href="/t5/custom/page/page-id/ideavotesdownload" class="lia-button lia-button-primary" id="clear-button-ak">Reset</a>
    </div>

    <@liaAddScript>
    ;(function($) {
        //START
        var boardList = [];
        var boardListString
        var voteList = [];
        var isMore = true;
        var offset = 0

        var generateButton = document.getElementById('generate-csv-button-ak');
            
        generateButton.addEventListener("click", function () {
            generateButton.disabled = true;
            getBoardList();
            getVotesList();
            createCsvDownload();
            console.log(voteList);
            
        })

        function getBoardList() {
            //get list of boards
            var getBoards = document.getElementsByClassName("board-checkbox-ak");
            for (i = 0; i < getBoards.length; i++) {
                if (getBoards[i].checked){
                    boardList.push(getBoards[i].value)
                }
            }

            //generate string from boardList
            for (i = 0; i < boardList.length; i++){
                boardList[i] = '"' + boardList[i] + '"';
            }
            boardListString = boardList.toString();

            console.log(boardListString);
        }

        function getVotesList() {
            while (isMore) {
                var apiCallString = "/api/2.0/search";
                var bodyString = '[{"messages":{"fields":["board.title","subject","status","view_href","author.login","author.sso_id","author.email","post_time","kudos"],"constraints":[{"board.id":{"in":['+ boardListString +']},"kudos.sum(weight)":{">":0},"depth":0}],"limit":1000,"offset":'+ offset +',"subQueries":{"kudos":{"fields":["time","user.email","user.login","user.sso_id"]}}}}]';
                var getVoteListReq = new XMLHttpRequest();
                getVoteListReq.open("POST", apiCallString, false);
                getVoteListReq.setRequestHeader('Content-type', 'application/json');

                getVoteListReq.onload = function(){
                    var resp = JSON.parse(getVoteListReq.response);
                    var size = resp.data.size;
                    if (size > 0){
                        console.log(resp.data.items);
                        voteList = voteList.concat(resp.data.items);
                        offset += 1000;
                    }
                    else{
                        isMore = false;
                        console.log("done");
                    }
                }//end onload

                getVoteListReq.send(bodyString);
            }
        }

        function createCsvDownload() {
            csvFile = 'Board,Idea,Idea URL,Idea Author,Author SSO ID,Author Email,Idea Date,Status,Voter,Voter SSO ID,Voter Email,Vote Date\r\n';

            for (i = 0; i < voteList.length; i++) {
                //format subject for csv
                var formattedSubject = strip(voteList[i].subject);
                formattedSubject = formattedSubject.replaceAll('"', '""');
                formattedSubject = '"' + formattedSubject + '"';

                //check for status
                if (voteList[i].status) {
                    var status = voteList[i].status.name;
                } else {
                    var status = "Unspecified";
                }

                //format post date
                var postDate = new Date(voteList[i].post_time);
                var formattedPostDate = (((postDate.getMonth() > 8) ? (postDate.getMonth() + 1) : ('0' + (postDate.getMonth() + 1))) + '/' + ((postDate.getDate() > 9) ? postDate.getDate() : ('0' + postDate.getDate())) + '/' + postDate.getFullYear());
                
                //format author login to "comma proof"
                var formattedAuthorLogin = voteList[i].author.login;
                formattedAuthorLogin = formattedAuthorLogin.replaceAll('"', '""');
                formattedAuthorLogin = '"' + formattedAuthorLogin + '"';


                for (j = 0; j < voteList[i].kudos.items.length; j++) {
                    //format voter login to "comma proof"
                    var formattedVoterLogin = voteList[i].kudos.items[j].user.login;
                    formattedVoterLogin = formattedVoterLogin.replaceAll('"', '""');
                    formattedVoterLogin = '"' + formattedVoterLogin + '"';

                    //format date for csv
                    var date = new Date(voteList[i].kudos.items[j].time);
                    var formattedDate = (((date.getMonth() > 8) ? (date.getMonth() + 1) : ('0' + (date.getMonth() + 1))) + '/' + ((date.getDate() > 9) ? date.getDate() : ('0' + date.getDate())) + '/' + date.getFullYear());
                    //var formattedDate = '"' + voteList[i].kudos.items[j].time + '"';

                    csvFile += (voteList[i].board.title + "," + formattedSubject + "," + voteList[i].view_href + "," + formattedAuthorLogin + "," + voteList[i].author.sso_id + "," + voteList[i].author.email + "," + formattedPostDate + "," + status + "," + formattedVoterLogin + "," + voteList[i].kudos.items[j].user.sso_id + "," + voteList[i].kudos.items[j].user.email + "," + formattedDate + "\r\n");
                }
            }

            var fileName = "Vote_Info";

            var downloader = document.createElement('a');
            downloader.setAttribute('href', 'data:text/csv;charset=utf-8,%EF%BB%BF' + encodeURIComponent(csvFile));
            downloader.setAttribute('download', fileName);
            downloader.setAttribute('id',"ak-download-button");
            downloader.setAttribute('class',"lia-button lia-button-primary");
            downloader.textContent = "Export CSV";

            var buttonList = document.getElementById('button-row-ak');
            buttonList.appendChild(downloader);
        }

        function strip(html){
            let doc = new DOMParser().parseFromString(html, 'text/html');
            return doc.body.textContent || "";
        }
        //END
    })(LITHIUM.jQuery);
    </@liaAddScript>


<#else>
	You are not authorized to access this page. Make sure you are logged in.
</#if>