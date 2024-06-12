import { Text } from "@fluentui/react";
import { Delete24Regular } from "@fluentui/react-icons";
import { newChat } from "../../api";
import styles from "./ClearChatButton.module.css";
 
 
interface Props {
    className?: string;
    onClick: () => void;
    disabled?: boolean;
}
declare global{
     var assistantId: string;
}
 
 
export const ClearChatButton = ({ className, disabled, onClick }: Props) => {
    const createNewChat = () => {
        const value = newChat(globalThis.assistantId);
        }
 
    return (
        <div className={`${styles.container} ${className ?? ""} ${disabled && styles.disabled}`} onClick={createNewChat}>
            <Delete24Regular />
            <Text>{"Clear chat"}</Text>
        </div>
    );
};