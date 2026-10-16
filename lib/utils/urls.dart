import 'package:cooli/helpers/url_helpers.dart';

String urlBase = UrlHelpers.baseURL;

// Google Maps API Key
const String googleMapsApiKey = 'AIzaSyD29p1a11QGiUsbYCTM1sPBkWpkLAHITqo';

// Authentication Endpoints
String urlSendOtp = "${urlBase}auth/send-otp/";
String urlSendLoginOtp = "${urlBase}auth/send-login-otp/";
String urlVerifyOtp = "${urlBase}auth/verify-otp/";
String urlLogin = "${urlBase}auth/login/";
String urlRegister = "${urlBase}auth/register/";
String urlProfile = "${urlBase}profile/";

// Home Screen Data
String urlHomeScreen = "${urlBase}home/";

// Goods Booking (Porter Model)
String urlGoodsVehicleTypes = "${urlBase}goods/vehicle-types/";
String urlGoodsCalculateFare = "${urlBase}goods/calculate-fare/";
String urlGoodsBookings = "${urlBase}goods/bookings/";
String urlGoodsBookingsList = "${urlBase}goods/bookings/list/";

// Ride Booking (Uber Model)
String urlRideVehicleTypes = "${urlBase}ride/vehicle-types/";
String urlRideCalculateFare = "${urlBase}ride/calculate-fare/";
String urlRideBookings = "${urlBase}ride/bookings/";
String urlRideBookingsList = "${urlBase}ride/bookings/list/";

// Transport (BlackBuck Model)
String urlTransportLoads = "${urlBase}transport/loads/";
String urlTransportLoadsList = "${urlBase}transport/loads/list/";
String urlTransportLoadsListByLocation = "${urlBase}transport/loads/list-by-location/";
String urlTransportLoadsListByTruckType = "${urlBase}transport/loads/list-by-truck-type/";
String urlTransportBids = "${urlBase}transport/bids/";
String urlTransportBidsList = "${urlBase}transport/bids/list/";
String urlTransportBookings = "${urlBase}transport/bookings/";
String urlTransportBookingsList = "${urlBase}transport/bookings/list/";
String urlVehicleTypesByService = "${urlBase}vehicle-types/by-service/";

// E-Commerce
String urlCategories = "${urlBase}categories/";
String urlProducts = "${urlBase}products/";
String urlCart = "${urlBase}cart/";
String urlCartAdd = "${urlBase}cart/add/";
String urlCartUpdate = "${urlBase}cart/update/";
String urlCartUpdateItem(int itemId) => "${urlBase}cart/update/$itemId/";
String urlCartRemoveItem(int itemId) => "${urlBase}cart/remove/$itemId/";
String urlOrders = "${urlBase}orders/";
String urlOrdersList = "${urlBase}orders/list/";

// Address & Payment & Wallet
String urlAddresses = "${urlBase}addresses/";
String urlPayments = "${urlBase}payments/";
String urlPaymentsList = "${urlBase}payments/list/";
String urlWallet = "${urlBase}wallet/";
String urlWalletAddFunds = "${urlBase}wallet/add-funds/";
String urlWalletTransactions = "${urlBase}wallet/transactions/";
String urlNotifications = "${urlBase}notifications/";
String urlSupportTickets = "${urlBase}support/tickets/";

//Register (Legacy / Fallback)
String urlRegistrationRequestOTP = "${urlBase}register/request-otp";
String urlRegistrationVerifyOTP = "${urlBase}register/verify-otp";
String urlRegistration = "${urlBase}register/store";

String urlLoginGenerateOrganization = "${urlBase}owner/mobile/login";
String urlLoginVerify = "${urlBase}owner/mobile/login/verify";
String urlGetDeviceUserCount = '${urlBase}owner/home/device-user-count';
String urlGetLicenseSummary = '${urlBase}owner/home/license-summary';
String urlGetDeviceList = '${urlBase}owner/device/list';
String urlGetDeviceGroupList = '${urlBase}owner/device-group/list';
String urlGetAddDeviceInDeviceGroup = '${urlBase}owner/device-group/add-device';
String urlGetAddDeviceGroup = '${urlBase}owner/device-group/add';
String urlGetDeviceGroupChangeName = '${urlBase}owner/device-group/change-name';
String urlGetDeviceGroupDeviceList = '${urlBase}owner/device-group/device-list';

String urlAddNewBTDevice = '${urlBase}owner/device/add';
String urlGetDeviceTypeList = '${urlBase}owner/device-type';
String urlGetRemoveDevice = '${urlBase}owner/device/remove';
String urlRemoveUserFromDeviceSharedList =
    '${urlBase}owner/device/device-key-revoke';
String urlGetUserDeleteDevice = '${urlBase}owner/user/delete-device';
String urlTransferDeviceKey = '${urlBase}owner/device/transfer-key/user';
String urlDeleteUserGroup = '${urlBase}owner/user-group/delete';
String urlAddUser = '${urlBase}owner/user/add';
String urlgetUserList = '${urlBase}owner/user/list';
String urlRemoveDeviceGroup = '${urlBase}owner/device-group/delete';
String urlAdminEnableBiometric = '${urlBase}owner/config/biometric-login/store';
