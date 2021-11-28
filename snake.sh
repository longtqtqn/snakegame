#!/bin/bash
#code by BuiHaiLong



#/*****************************/#
#     CREATE HEIGHT & WIDTH     #
#*******************************#
#***#
#   detail:     create board_game follow size of terminal
#***#
#height of board
declare -i board_height=$(($(tput lines)-5))
#width of board
declare -i board_width=$(($(tput cols)-2))

#-----------------------------------------------------------------------------------#


#/*****************************/#
#         CHECK TERMINAL        #
#*******************************#
#*******************************************#
#     detail:   size is too small, exit     #
#*******************************************#
#check height and width of terminal
check_terminal(){
    if (($board_height < 20))
    then
        echo "Terminal's size is too small. It height: $board_height"
        exit 1
    fi

    if (($board_width < 50))
    then
        echo "Terminal's size is too small. It width: $board_width"
        exit 1
    fi
}
#-----------------------------------------------------------------------------------#


#set IFS, if not set, dinstance beetween 2 'char space" is large
IFS=''


#/*****************************/#
#        ALIAS SIGNAL           #
#*******************************#
#**********************************************************************************#
#   detail:  alias for key pressed to signal                                       |
#            use the signal available in ubuntu: USR1, USR2, URG, IO, WINCH, HUP   |
#            from that signal transform signal for game                            |
#**********************************************************************************#
# signals
SIG_UP=USR1
SIG_RIGHT=USR2
SIG_DOWN=URG
SIG_LEFT=IO
SIG_QUIT=WINCH
SIG_DEAD=HUP

#-----------------------------------------------------------------------------------#


#/*****************************/#
#       GAME DISPLAY            #
#*******************************#

#create board game
#**********************************************************************************#
#   detail:   create array, save postion of snake, space, food                     |
#             set variable game_is_running                                         |
#**********************************************************************************#
create_board_game(){
   
    clear
    game_is_running=1
    for ((i=0; i<board_height; i++)); do
        for ((j=0; j<board_width; j++)); do
            eval "board_game$i[$j]=' '"
        done
    done

}


#30: font black; 41: background red
border_color="\e[30;41m"
#97: font white; 42: background green
#reset all attributes
reset_color="\e[0m"

#game display
#*********************************************#
#   detail:   create rectangle in terminal    |    
#*********************************************#
game_display(){
  
    #create |-------------------|
    echo -ne "\e[1;1H$border_color+$reset_color"
    for ((i=2; i<=board_width+1; i++))
    do
        echo -ne "\e[1;$iH$border_color-$reset_color"
    done
    echo -ne "\e[1;$((board_width + 2))H$border_color|$reset_color"

    #create
    #       |                   |        
    #       |                   |
    #       |                   |        
    #       |                   |
  

    for ((i=0; i<board_height; i++)); do
        echo -ne "\e[$((i+2));1H$border_color|$reset_color"
        eval echo -en "\"\${board_game$i[*]}\""
        echo -ne "\e[H$border_color|$reset_color"
        echo -ne "\e[$((i+2));$((board_width + 2))H$border_color|$reset_color"
    done

    #create |-------------------|
    echo -ne "\e[$((board_height+2));1H$border_color|$reset_color"
    for ((i=2; i<=board_width+1; i++))
    do
        echo -ne "\e[$((board_height+2));$iH$border_color-$reset_color"
    done
    echo -ne "\e[$((board_height+2));$((board_width + 2))H$border_color|$reset_color"
}

#------------------------------------------------------------------------------#

#/*****************************/#
#          SNAKE & FOOD         #
#*******************************#

#game score
declare -i game_score=0

#create color head of snake
head_snake="\e[30;100m"

#create color for food
food_snake="\e[36;47m"


#speed of snake 
speed_snake=0.06


#head_snake
head_pos_r=16
head_pos_c=30

#tail_snake
tail_pos_r=18
tail_pos_c=30

#track of snake
track_snake_move="uuu"

#random food
#*******************************************************#
#   detail:    create random number                     |
#              after check it, assure it locate space   |
#*******************************************************#
random_food() {
    #create row and col
    food_r=$((RANDOM % board_height))
    food_c=$((RANDOM % board_width))
    
    #create random postion
    eval "position=\${board_game$food_r[$food_c]}"
    
    #check position
    while [ "$position" != ' ' ]
    do
        food_r=$((RANDOM % board_height))
        food_c=$((RANDOM % board_width))
        eval "position=\${board_game$food_r[$food_c]}"
    done

    #print food to terminal
    icon='S'
    eval "board_game$food_r[$food_c]=\"$food_snake$icon$reset_color\""
}


#create default snake
#*******************************************************#
#   detail:    initialize snake before game start       |
#*******************************************************#
create_snake_default(){

    head_pos_r1=$((head_pos_r+1))
    head_pos_r2=$((head_pos_r+2))
    eval "board_game$head_pos_r[$head_pos_c]=\"${head_snake}*$reset_color\""
    eval "board_game$head_pos_r1[$head_pos_c]=\"${head_snake}*$reset_color\""
    eval "board_game$head_pos_r2[$head_pos_c]=\"${head_snake}*$reset_color\""

}

#check snake move in space
check_move_space() {

    #check position is in space of game
    if [ "$1" -lt 0 ] || [ "$1" -ge "$board_height" ] ||  [ "$2" -lt 0 ] || [ "$2" -ge "$board_width" ]
    then
        return 0
    fi

    eval "tmp=\${board_game$1[$2]}"
    #if condition true, head of snake hit it's body
    if [ "$tmp" == "${head_snake}*$reset_color" ]
    then
        return 0
    fi
    return 1
}

#create snake have just moved
create_snake_moved(){

    #get position of snake's head
    case "$snake_move" in
            UP) 
                head_pos_r=$((head_pos_r-1))
                ;;
            DOWN) 
                head_pos_r=$((head_pos_r+1))
                ;;
            RIGHT) 
                head_pos_c=$((head_pos_c+1))
                ;;
            LEFT) 
                head_pos_c=$((head_pos_c-1))
                ;;
    esac

    #check snake hit wall or hit body
    if $(check_move_space $head_pos_r $head_pos_c); then
        game_is_running=0
        return
    fi

    #create variable to check if snake eat food
    icon='S'
    eval "posistion_check_food=\${board_game$head_pos_r[$head_pos_c]}"
    if [ "$posistion_check_food" == "$food_snake$icon$reset_color" ]
    then
        eval "board_game$head_pos_r[$head_pos_c]=\"${head_snake}*$reset_color\""
        game_score+=1
        random_food;

        #set track of snake's head if eat food
        case "$snake_move" in
            UP) 
                track_snake_move="u"$track_snake_move
                ;;
            DOWN) 
                track_snake_move="d"$track_snake_move
                ;;
            RIGHT) 
                track_snake_move="r"$track_snake_move
                ;;
            LEFT) 
                track_snake_move="l"$track_snake_move
                ;;
    esac
        return
    fi

    #set track of snake's head if not eat food
    case "$snake_move" in
            UP) 
                track_snake_move="u"${track_snake_move: 0: -1}
                ;;
            DOWN) 
                track_snake_move="d"${track_snake_move: 0: -1}
                ;;
            RIGHT) 
                track_snake_move="r"${track_snake_move: 0: -1}
                ;;
            LEFT) 
                track_snake_move="l"${track_snake_move: 0: -1}
                ;;
    esac

    eval "board_game$head_pos_r[$head_pos_c]=\"${head_snake}*$reset_color\""
    
    #if no eat food delete tail
        eval "board_game$tail_pos_r[$tail_pos_c]=' '"
        get_track_move=${track_snake_move: -1}
        case "$get_track_move" in
                u)  
                    tail_pos_r=$((tail_pos_r-1))
                    ;;
                d) 
                    tail_pos_r=$((tail_pos_r+1))
                    ;;
                r) 
                    tail_pos_c=$((tail_pos_c+1))
                    ;;
                l) 
                    tail_pos_c=$((tail_pos_c-1))
                    ;;
        esac
   

}


#----------------------------------------------------------------------------#

#/*****************************/#
#       GAME CONTROL            #
#*******************************#

#create signal form keyboard
create_keypress() {
    trap "" SIGINT SIGQUIT
    trap "return;" $SIG_DEAD
    while true; do

        #flag -n1 , read sigal character
        read -s -n 1 key
        case "$key" in
            [qQ]) kill -$SIG_QUIT $last_background_pid  
                  return
                  ;;
            [wW]) kill -$SIG_UP $last_background_pid
                  ;;
            [dD]) kill -$SIG_RIGHT $last_background_pid
                  ;;
            [sS]) kill -$SIG_DOWN $last_background_pid
                  ;;
            [aA]) kill -$SIG_LEFT $last_background_pid
                  ;;
       esac
    done
}

#get signal form keyboard
keypressed='n'
snake_move='UP'
get_keypress() {
    trap "keypressed='u';" $SIG_UP
    trap "keypressed='r';" $SIG_RIGHT
    trap "keypressed='d';" $SIG_DOWN
    trap "keypressed='l';" $SIG_LEFT
    trap "exit 1;" $SIG_QUIT

    while [ "$game_is_running" -eq 1 ]
    do

        case "$keypressed" in
            u)  
                if [ $snake_move != 'DOWN' ]
                then
                    snake_move='UP'
                    keypressed='n'
                fi
                ;;
            d) 

                if [ $snake_move != 'UP' ]
                then
                    snake_move='DOWN'
                    keypressed='n'
                fi
                ;;
            r) 
                if [ $snake_move != 'LEFT' ]
                then
                    snake_move='RIGHT'
                    keypressed='n'
                fi
                ;;
            l) 
                if [ $snake_move != 'RIGHT' ]
                then
                    snake_move='LEFT'
                    keypressed='n'
                fi
                ;;
        esac
        
        create_snake_moved
        game_display
        sleep $speed_snake
    done
    
    echo -e "${gameover_color}GAME OVER!!!!!    YOUR SCORE: $game_score"
    # signals the input loop that the snake is dead
    kill -$SIG_DEAD $$
}

#---------------------------------------------------------------------------#

#/*****************************/#
#           MAIN                #
#*******************************#

#check size of terminal
check_terminal

#initialize
create_board_game
create_snake_default
random_food
game_display


#set up control
get_keypress &
#pid for last background progress
last_background_pid=$!
create_keypress
