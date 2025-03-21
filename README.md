# Pomodorian

A minimal, vibe-coded MacOS native Pomodoro timer in your statusbar.

- 400kb binary when built
- App file is bigger, but that's just because the icon file is bigger than the app - LOL.
- I already had Xcode configured to build MacOS apps, but I was still amazed that I never opened Xcode during development.

## About

I was looking to try out a vibe coding experience with Claude Sonnet 3.7 when it was first released, especially since I'd gotten access to Claude Code as well. Having already had a lot of productivity gains building [Traffi](https://traffi.skcfi.dev) with 3.5, I was excited. I thought to try writing a simple, native MacOS app. Pomodorian is the result.

I had planned to document the prompts and conversation in this repo as well, but I tragically lost them. I do however,
have some excellent examples of how I used screenshots to iron out UI bugs and make modifications with a little documentation about that. These are in the `VibingScreenshots` folder.

I also had two quick scripts which I would have Claude execute, one to kill, build and start the app so I could inspect the changes (`try_accept.sh`), and the other (`test_icon.sh`), to check that icons were properly installed. The latter one I had Claude write, because it seemed to have trouble installing the icon I had made properly. Asking for a verifiable tests is great, because you can often just ask Claude to keep trying until it fixes it, with a strong caution to always examine its history to ensure it's not trying things it already has.

I've also added a white space cleaning script, which I probably should have done from the start to make comparing diffs a little less horrible. But hey, learn from my lesson.

## Installation

IDK it's a Mac app. Install Xcode, ensure you're set up for running MacOS apps on your current OS, and then run:
```
./build.sh
open build/Pomodorian.app   # Or move it to /Applications/ if you like.
```
