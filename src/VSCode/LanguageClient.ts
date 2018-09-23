import { LanguageClient, ExecuteCommandRequest } from 'vscode-languageclient';

export const sendCommandImpl = (client: LanguageClient) => (command: string) => (args?: any[]) => 
    (errCb: (err: Error) => () => {}) => <T>(cb: (arg: T) => () => {}) => () => 
        client.sendRequest(ExecuteCommandRequest.type, { command, arguments: args }).then(res => {
            cb(res)();
        }, err => {
            errCb(err)();
        });

export const onNotification0 = (client: LanguageClient) => (notification: string) => (cb: () => {}) => () =>
    client.onNotification(notification, cb);
