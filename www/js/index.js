window.onload = (function() {

    var fSubmit = function(sSubmit, fCallback) {
        var oRequest = null;

        if (window.XMLHttpRequest) {
            oRequest = new XMLHttpRequest();
        } else if (window.ActiveXObject) {
            try {
                oRequest = new ActiveXObject("Msxml2.XMLHTTP");
            } catch (e) {
                try {
                    oRequest = new ActiveXObject("Microsoft.XMLHTTP");
                } catch (e) {
                    // ...
                }
            }
        }

        oRequest.onreadystatechange = function() {
            if (oRequest.readyState === 4) {
                fCallback(oRequest);
            }
        }

        oRequest.open('POST', '/cgi/login/auth', true);
        oRequest.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        oRequest.send(sSubmit);
    };

    var fVisual = function(bShow) {
        var oAuth = document.getElementById('auth'),
            oPanel = oAuth.getElementsByTagName('section');
        oPanel[0].className = bShow ? 'hidden' : 'loading';
        oPanel[1].className = bShow ? '' : 'hidden';
        return oPanel[1];
    };

    var fResponse = function(o) {
        if (parseInt(o.status) === 200) {
            fVisual( true );
            var aResponse = JSON.parse(o.responseText);
        } else if (parseInt(o.status) === 302) {
            location.href = o.response.href;
        } else {
            var oMssgPanel = fVisual( false );
            oMssgPanel.innerHTML = o.response ? o.response.error : o.responseText;
        }
        o = null;
    };

    var fFormsInit = function() {
        document.getElementById('form_registry').onclick = function() {
            document.token.pssw.value = '';
            document.token.login.value = '';
        };
        document.getElementById('form_forget').onclick = function() {
            document.token.pssw.value = '';
        };

        var aForms = document.getElementsByTagName('form');
        for (var i = 0; i < aForms.length; i++) {
            aForms[i].onsubmit = function() {
                var aRequest = [];
                for (var i = 0; i < this.length; i++) {
                    if (this[i].name && this[i].value) {
                        aRequest.push(this[i].name + '=' + this[i].value);
                    }
                }
                fSubmit(aRequest.join('&'), fResponse);
                return false;
            };
        }
    };

    return function() {
        fFormsInit();
        var oAuth = document.getElementById('auth');
        var oPanel = oAuth.getElementsByTagName('li');
        for (var i = 0; i < oPanel.length; i++) {
            oPanel[i].onclick = function() {
                var aDivs = oAuth.getElementsByTagName('div'),
                        iCurrent = 0;
                for (var j = 0; j < aDivs.length; j++) {
                    aDivs[j].className = 'hidden';
                    oPanel[j].className = '';
                    if (oPanel[j] === this) {
                        var iCurrent = j;
                    }
                }
                aDivs[iCurrent].className = 'active';
                oPanel[iCurrent].className = 'active';
            };
        }

        if (!navigator.cookieEnabled) {
            oAuth.querySelectorAll('.loading')[0].innerHTML = 'Enable cookies first!';
        } else {
            var aToken = document.cookie.match(new RegExp("(?:^|; )token=([^;]*)"));
            if (aToken) {
                fSubmit('cookie=' + decodeURIComponent(aToken[1]), fResponse);
            } else {
                fVisual( true );
            }
        }
    };
})();