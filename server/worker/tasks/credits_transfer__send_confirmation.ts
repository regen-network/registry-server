import { Task } from 'graphile-worker';

import { SendEmailPayload, dateFormat, numberFormat } from './send_email';

interface CreditsTransferSendConfirmationPayload {
  // purchaseId: string;
  // ownerName: string;
  // project: {
  //   name: string;
  //   image: string;
  //   location: {
  //     place_name: string;
  //   };
  //   area: number;
  //   areaUnit: string;
  //   metadata: {
  //     url: string;
  //   };
  // };
  creditClass: {
    name: string;
    metadata: {
      purchaseSummary: string;
      purchaseShare: string;
      type: string;
    };
  };
  // quantity: number;
  // amount: number;
  // currency: string;
  email: string;
  receiptUrl: string;
}

const task: Task = async (inPayload, { addJob }) => {
  const {
    email,
    creditClass,
  }: CreditsTransferSendConfirmationPayload = inPayload as any;
  const sendEmailPayload: SendEmailPayload = {
    options: {
      to: email,
      subject: 'Thank you for regenerating the planet!',
    },
    template: 'confirm_credits_transfer.mjml',
    variables: {
      creditClassSpread: creditClass.metadata.purchaseShare,
      receiptUrl: '',
      summary: creditClass.metadata.purchaseSummary,
      // summary: 'Your purchase restores healthy grasslands, sequesters carbon in soil, increases biodiversity, and improves animal welfare.',
      // Variables for older email version,
      // keeping it here just in case...
      // purchaseId: purchaseId.slice(0, 8),
      // ownerName,
      // projectName: project.name,
      // projectImage: project.image,
      // projectLocation: project.location.place_name,
      // projectArea: project.area,
      // projectAreaUnit: project.areaUnit,
      // projectLink: project.metadata.url,
      // creditClassName: creditClass.name,
      // creditClassType: creditClass.metadata.type,
      // quantity,
      // amount: numberFormat.format(amount),
      // currency: currency.toUpperCase(),
      // date: dateFormat.format(new Date()),
    },
  };
  await addJob('send_email', sendEmailPayload);
};

export default task;
