var parentWin = (!window.frameElement && window.dialogArguments) || opener || parent || top;
window.angular = parentWin.angular;
window.angular.module('file-manager-popup', [
  'VitalCms.controllers.fileManagerPopup',
  'VitalCms.services',
  'angularFileUpload'
]);
window.angular.element(document).ready(function() {
  window.angular.bootstrap(document.getElementById('file-manager'), ['file-manager-popup']);
});
