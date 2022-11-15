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
                var bodyString = '[{"messages":{"fields":["board.title","subject","status","kudos"],"constraints":[{"board.id":{"in":['+ boardListString +']},"kudos.sum(weight)":{">":0},"depth":0}],"limit":1000,"offset":'+ offset +',"subQueries":{"kudos":{"fields":["time","user.email"]}}}}]';
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
            csvFile = 'Board,Idea,Status,Email,Date\r\n';

            for (i = 0; i < voteList.length; i++) {
                //format subject for csv
                var formattedSubject = strip(voteList[i].subject);
                formattedSubject = formattedSubject.replaceAll('"', '""');
                formattedSubject = '"' + formattedSubject + '"';

                //check for status
                if (voteList[i].status) {
                    var status = voteList[i].status.name;
                } else {
                    var status = "No Status";
                }

                for (j = 0; j < voteList[i].kudos.items.length; j++) {
                    //format date for csv
                    var date = new Date(voteList[i].kudos.items[j].time);
                    var formattedDate = (((date.getMonth() > 8) ? (date.getMonth() + 1) : ('0' + (date.getMonth() + 1))) + '/' + ((date.getDate() > 9) ? date.getDate() : ('0' + date.getDate())) + '/' + date.getFullYear());
                    //var formattedDate = '"' + voteList[i].kudos.items[j].time + '"';

                    csvFile += (voteList[i].board.title + "," + formattedSubject + "," + status + "," + voteList[i].kudos.items[j].user.email + "," + formattedDate + "\r\n");
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