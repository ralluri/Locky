#!/bin/bash
#
# Locky: lock ALL screens at suspend or hibernate with xscreensaver 
# or another command. Call this from a suspend or hibernate hook.

# Source locky configuration
if [[ -f /etc/lockyrc ]]; then
	source /etc/lockyrc
else
	echo "There was no valid /etc/lockyrc file. Please make one."
	exit 1
fi

check_if_lock()
{
	if [ ${#users_to_ignore[@]} -lt 1 ];then
		return 1;
	fi
	for i in ${users_to_ignore[@]}
	do
		if [ "$i" == "$1" ]; then
			return 0;
		fi
	done
	return 1;
}

lock_me ()
{
# check if xscreensaver or whatever is running. if not, just skip on.
if [ -z "$IS_ACTIVE" ]
	then :
		echo "$lock_error"
	else
		if [[ $1 = hibernate ]];then
			echo "$hibernate_lock_msg"
		else
			echo "$suspend_lock_msg"
		fi
		 # run the lock command as the user who owns xscreensaver process,
		 # and not as root, which won't work.
		 # Feed correct display variable for user!
	echo "$IS_ACTIVE"|while read line;
	do
		user="$(getent passwd $line |awk -F : '{print $1}')"
		if $(check_if_lock $user);then
			continue;
		fi
		echo "$DISPLAYS_TO_CHECK"|tr " " "\n"|while read displays;
		do
			if xdpyinfo=$(su - $user -c "xdpyinfo -display ${displays}.0 2>&1 1>/dev/null"); then
				echo "$user : DISPLAY=$displays $lock_command"
				su - $user -c "DISPLAY=$displays $lock_command" &
			fi
		done
	done
fi
}

case $1 in
	pre)
		case $2 in
				hibernate)
					  echo "$hibernate_msg"
					  lock_me
					  ;;
				suspend)
					  echo "$suspend_msg"
					  lock_me
					  ;;
		esac
		;;
	post)
		case $2 in
			hibernate)
				 echo "$thaw_msg"
				 ;;
			suspend)
				 echo "$resume_msg"
				 ;;
		esac
		;;
	*) 
		echo "$other_action_msg"
		 ;;
esac
