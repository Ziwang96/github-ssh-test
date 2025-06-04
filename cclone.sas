data work.x;
RC = GIT_CLONE("git@github.com:Ziwang96/github-ssh-test.git", "/dmtesting/Products/Lineage/Misc/GitTemp/ziheng12", "git", "", "/dmtesting/Products/Lineage/Misc/GitTemp/sshTest_ed25519.pub", "/dmtesting/Products/Lineage/Misc/GitTemp/sshTest_ed25519", "", 2, "etl_ssh");
/* run;  */
proc print data=work.x; 
/* run; */asdasdasdasd