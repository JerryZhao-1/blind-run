## 1. Blind Flow Navigation

- [x] 1.1 Update the blind request submission success path to return to `/blind` after a successful order creation.
- [x] 1.2 Ensure the blind home flow refreshes current blind orders when the page is entered.

## 2. Blind Home And Detail Presentation

- [x] 2.1 Update the blind home page to present the active order summary with status, place, time, and a primary “查看当前订单” action.
- [x] 2.2 Add an explicit “返回主页” action to the blind active-order page while preserving existing polling behavior.

## 3. Verification

- [x] 3.1 Add widget coverage for successful blind order creation returning to home instead of the detail page.
- [x] 3.2 Add widget coverage for home-page order refresh and active-order summary rendering.
- [x] 3.3 Add widget coverage for navigating from home to active-order detail and returning to home.
