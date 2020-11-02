# How to use git... so far

## Upload a file

You need to perform a couple of steps:

First add the file to make it part of the git (test):

    git add filename

Then commit to it with a comment:
	git commit -m "This is my comment"
Then push the file to git:
	git push

At this point you will be asked for your username and password.

## Upload a file in a folder (and the folder itself).

Keep your assets (pictures and other media) separate in a folder named **assets**. Then add them to the git.

    git add folder/media.png

And then follow through with the same commands:

    git commint -m "A new media file in the assets folder"
    git push

And it's done.

## Make aliases of common commands

If you fed up typing all this crap, you can make shortcuts or *aliases* by doint:

You can do this once per session, like:

	git config --global alias.ci commit

This makes **ci** a shortcut to **commit**.

Or you can dit the **.gitconfig** file in your **$HOME** directory (that implies home dir, not just the git folder).

Add:

	[alias]
	co = checkout
	ci = commit
	st = status
	br = branch
	hist = log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short
	type = cat-file -t
	dump = cat-file -p

This is a good start, I will add more as I use this more.
