# Your 2-Minute To-Do List

## Step 1 — Update the security rules (required)

1. Click this link: **https://console.firebase.google.com/project/goalshare-966d1/firestore/rules**
   (log in with the same Google account you used to set up Firebase)
2. Open the file **`firestore.rules`** in this project, select ALL of it, copy.
3. Back in the Firebase page: delete what's in the big text box, paste, click **Publish**.

Done. This turns on message editing + cloud backup.

## Step 2 — Test notifications (after the next Codemagic build)

1. Install the new build on two phones.
2. Close the app completely on phone A (swipe it away).
3. From phone B, send phone A a message.
4. Banner pops up on phone A? ✅ Everything works — you're finished.
5. No banner? Tell the agent "no banner" and you'll get the 5-minute Railway fix.

That's the whole list.
